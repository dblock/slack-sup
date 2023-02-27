# frozen_string_literal: true

require 'spec_helper'

describe 'events/member_joined_channel' do
  include_context :event

  let(:event) do
    {
      type: 'member_joined_channel',
      team: team.team_id,
      user: team.bot_user_id,
      channel: 'channel_id',
      inviter: 'iviter_id'
    }
  end

  it 'posts a welcome message' do
    expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).with(
      channel: 'channel_id', text: /Hi there!/
    )

    expect do
      post '/api/slack/event', event_envelope
      expect(last_response.status).to eq 201
      expect(JSON.parse(last_response.body)).to eq('ok' => true)
    end.to change(Channel, :count).by(1)
  end

  context 'when the bot is already a member of a channel' do
    let!(:channel) { Fabricate(:channel, team: team, channel_id: 'channel_id') }

    it 'welcomes the bot again' do
      expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).with(
        hash_including(channel: 'channel_id')
      )

      expect do
        post '/api/slack/event', event_envelope
        expect(last_response.status).to eq 201
        expect(JSON.parse(last_response.body)).to eq('ok' => true)
      end.to_not change(Channel, :count)
    end
  end
end
