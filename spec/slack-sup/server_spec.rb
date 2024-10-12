require 'spec_helper'

describe SlackSup::Server do
  subject do
    SlackSup::Server.new(team:)
  end

  let(:team) { Fabricate(:team) }
  let(:client) { subject.send(:client) }

  describe '#channel_joined' do
    it 'sends a welcome message' do
      expect(client).to receive(:say).with(channel: 'C12345', text: "Hi there! I'm your team's S'Up bot. Type `@sup help` for instructions.")
      client.send(:callback, Hashie::Mash.new('channel' => { 'id' => 'C12345' }), :channel_joined)
    end
  end
end
