require 'spec_helper'

describe Api::Endpoints::SlackEndpoint do
  include Api::Test::EndpointTest

  context 'outcome' do
    let(:sup) { Fabricate(:sup) }
    it 'parses a valid payload and returns updated outcome' do
      post '/api/slack/action', payload: {
        'actions': [{ 'name' => 'outcome', 'type' => 'button', 'value' => 'none' }],
        'callback_id': sup.id.to_s,
        'channel': { 'id' => '424242424', 'name' => 'directmessage' },
        'original_message': {
          'ts': '1467321295.000010'
        }
      }.to_json
      expect(last_response.status).to eq 201
      payload = JSON.parse(last_response.body)
      expect(payload['text']).to eq 'Thanks for letting me know.'
      expect(payload['attachments'].first['actions'].map { |a| a['style'] }).to eq(%w[default default primary])
      expect(sup.reload.outcome).to eq 'none'
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
    expect(JSON.parse(last_response.body)['error']).to eq 'Missing actions.'
  end

  it 'requires payload with at least one action' do
    post '/api/slack/action', payload: {
      'actions': []
    }.to_json
    expect(last_response.status).to eq 400
    expect(JSON.parse(last_response.body)['error']).to eq 'Missing action.'
  end

  context 'with a SLACK_VERIFICATION_TOKEN' do
    before do
      ENV['SLACK_VERIFICATION_TOKEN'] = 'token'
    end
    after do
      ENV.delete 'SLACK_VERIFICATION_TOKEN'
    end
    it 'returns an error with a non-matching verification token', vcr: { cassette_name: 'msft' } do
      post '/api/slack/action', payload: {
        'token': 'invalid'
      }.to_json
      expect(last_response.status).to eq 401
      expect(JSON.parse(last_response.body)['error']).to eq 'Message token is not coming from Slack.'
    end
  end
end
