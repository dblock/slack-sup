# frozen_string_literal: true

require 'spec_helper'

describe 'events/member_left_channel' do
  include_context :event

  let(:event) do
    {
      type: 'member_left_channel',
      team: team.team_id,
      user: team.bot_user_id,
      channel: 'channel_id',
      inviter: 'iviter_id'
    }
  end

  it 'does nothing' do
    post '/api/slack/event', event_envelope
    expect(last_response.status).to eq 201
    expect(JSON.parse(last_response.body)).to eq('ok' => true)
  end

  context 'with a channel' do
    let!(:channel) { Fabricate(:channel, team: team, channel_id: event[:channel]) }

    it 'removes bot from channel' do
      expect(channel.enabled).to be true
      post '/api/slack/event', event_envelope
      expect(last_response.status).to eq 201
      expect(JSON.parse(last_response.body)).to eq('ok' => true)
      expect(channel.reload.enabled).to be false
    end
  end
end
