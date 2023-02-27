require 'spec_helper'

describe Api::Endpoints::SlackEndpoint do
  include Api::Test::EndpointTest

  before do
    allow_any_instance_of(Slack::Events::Request).to receive(:verify!)
  end

  context 'outcome' do
    let(:sup) { Fabricate(:sup) }

    let(:payload) do
      {
        type: 'interactive_message',
        user: { id: 'user_id' },
        team: { id: 'team_id' },
        callback_id: sup.id.to_s,
        channel: { id: '424242424', name: 'directmessage' },
        original_message: {
          ts: '1467321295.000010'
        },
        response_url: 'https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX',
        token: 'deprecated'
      }
    end

    context 'none' do
      it 'updates outcome' do
        expect(Faraday).to receive(:post).with('https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX', {
          response_type: 'in_channel',
          thread_ts: '1467321295.000010',
          text: 'Thanks for letting me know.',
          attachments: [
            text: '',
            attachment_type: 'default',
            actions: [
              { name: 'outcome', text: 'We All Met', type: 'button', value: 'all', style: 'default' },
              { name: 'outcome', text: 'Some of Us Met', type: 'button', value: 'some', style: 'default' },
              { name: 'outcome', text: "We Haven't Met Yet", type: 'button', value: 'later', style: 'default' },
              { name: 'outcome', text: "We Couldn't Meet", type: 'button', value: 'none', style: 'primary' }
            ],
            callback_id: sup.id.to_s
          ]
        }.to_json, 'Content-Type' => 'application/json')
        post '/api/slack/action', payload: payload.merge(
          actions: [
            { name: 'outcome', type: 'button', value: 'none' }
          ]
        ).to_json
        expect(last_response.status).to eq 204
        expect(sup.reload.outcome).to eq 'none'
      end
    end

    context 'later' do
      it 'delays reminding by 48 hours' do
        expect(Faraday).to receive(:post).with('https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX', {
          response_type: 'in_channel',
          thread_ts: '1467321295.000010',
          text: "Thanks, I'll ask again in a couple of days.",
          attachments: [
            text: '',
            attachment_type: 'default',
            actions: [
              { name: 'outcome', text: 'We All Met', type: 'button', value: 'all', style: 'default' },
              { name: 'outcome', text: 'Some of Us Met', type: 'button', value: 'some', style: 'default' },
              { name: 'outcome', text: "We Haven't Met Yet", type: 'button', value: 'later', style: 'primary' },
              { name: 'outcome', text: "We Couldn't Meet", type: 'button', value: 'none', style: 'default' }
            ],
            callback_id: sup.id.to_s
          ]
        }.to_json, 'Content-Type' => 'application/json')

        post '/api/slack/action', payload: payload.merge(
          'actions': [
            { name: 'outcome', type: 'button', value: 'later' }
          ]
        ).to_json
        expect(last_response.status).to eq 204
        expect(sup.reload.outcome).to eq 'later'
      end
    end
  end

  it 'requires payload' do
    post '/api/slack/action'
    expect(last_response.status).to eq 400
    expect(JSON.parse(last_response.body)['message']).to eq 'Invalid parameters.'
  end

  it 'requires payload with actions' do
    post '/api/slack/action', payload: {
    }.to_json
    expect(last_response.status).to eq 400
    expect(JSON.parse(last_response.body)['type']).to eq 'param_error'
  end
end
