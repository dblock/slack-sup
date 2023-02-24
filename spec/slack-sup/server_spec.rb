require 'spec_helper'

describe SlackSup::Server do
  let(:team) { Fabricate(:team) }
  let(:client) { subject.send(:client) }
  subject do
    SlackSup::Server.new(team: team)
  end
  before do
    client.owner.bot_user_id = 'bot_user_id'
  end
  context '#member_joined_channel' do
    it 'sends a welcome message' do
      expect(client).to receive(:say).with(channel: 'C12345', text: [
        "Hi there! I'm your team's S'Up bot. Thanks for trying me out. Type `@sup help` for instructions.",
        "I plan to setup some S'Ups via Slack DM for all users in this channel next Monday.",
        'You may want to `set size`, `set day`, `set timezone`, or `set sync now` users before then.'
      ].join(' '))
      expect do
        client.send(:callback, Hashie::Mash.new('channel' => 'C12345', 'user' => 'bot_user_id', 'inviter' => 'inviter'), :member_joined_channel)
      end.to change(Channel, :count).by(1)
    end
    context 'with an existing channel' do
      let!(:channel) { Fabricate(:channel, channel_id: 'C12345') }
      it 'sends a welcome message' do
        expect(client).to receive(:say).with(channel: 'C12345', text: [
          "Hi there! I'm your team's S'Up bot. Thanks for trying me out. Type `@sup help` for instructions.",
          "I plan to setup some S'Ups via Slack DM for all users in this channel next Monday.",
          'You may want to `set size`, `set day`, `set timezone`, or `set sync now` users before then.'
        ].join(' '))
        expect do
          client.send(:callback, Hashie::Mash.new('channel' => 'C12345', 'user' => 'bot_user_id', 'inviter' => 'inviter'), :member_joined_channel)
        end.to_not change(Channel, :count)
      end
    end
  end
  context '#member_left_channel' do
    let!(:channel) { Fabricate(:channel, channel_id: 'C12345') }
    it 'deactivates a channel when the bot leaves a channel' do
      client.send(:callback, Hashie::Mash.new('channel' => 'C12345', 'user' => 'bot_user_id'), :member_left_channel)
      expect(channel.reload.enabled).to be false
    end
    it 'does not deactivate another channel' do
      client.send(:callback, Hashie::Mash.new('channel' => 'other', 'user' => 'bot_user_id'), :member_left_channel)
      expect(channel.reload.enabled).to be true
    end
  end
end
