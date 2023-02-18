require 'spec_helper'

describe SlackSup::Server do
  let(:team) { Fabricate(:team) }
  let(:client) { subject.send(:client) }
  subject do
    SlackSup::Server.new(team: team)
  end
  context '#channel_joined' do
    it 'sends a welcome message' do
      expect(client).to receive(:say).with(channel: 'C12345', text: "Hi there! I'm your team's S'Up bot. Type `@sup help` for instructions.")
      client.send(:callback, Hashie::Mash.new('channel' => { 'id' => 'C12345' }), :channel_joined)
    end
  end
  context '#member_joined_channel' do
    pending 'creates a channel when the bot joins a channel'
  end
  context '#member_left_channel' do
    pending 'deactivates a channel when the bot leaves a channel'
  end
end
