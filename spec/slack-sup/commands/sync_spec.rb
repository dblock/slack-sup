require 'spec_helper'

describe SlackSup::Commands::Sync do
  context 'dm' do
    include_context :subscribed_team

    it 'does not sync' do
      expect(message: "#{SlackRubyBot.config.user} sync", channel: 'DM').to respond_with_slack_message(
        'Please run this command in a channel.'
      )
    end
  end
  context 'channel' do
    include_context :channel

    context 'as admin' do
      before do
        expect_any_instance_of(User).to receive(:channel_admin?).and_return(true)
      end
      it 'sync' do
        expect(message: "#{SlackRubyBot.config.user} sync").to respond_with_slack_message(
          'Users will sync in the next hour. Come back and run `stats` in a bit.'
        )
      end
    end
    context 'as non admin' do
      before do
        expect_any_instance_of(User).to receive(:channel_admin?).and_return(false)
      end
      it 'sets sync' do
        expect(message: "#{SlackRubyBot.config.user} sync").to respond_with_slack_message(
          "Users will sync before the next round. Only <@#{channel.inviter_id}> or a Slack team admin can manually sync, sorry."
        )
      end
    end
  end
end
