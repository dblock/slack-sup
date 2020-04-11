require 'spec_helper'

describe SlackSup::Commands::Help do
  let(:app) { SlackSup::Server.new(team: team) }
  let(:client) { app.send(:client) }
  context 'subscribed team' do
    let!(:team) { Fabricate(:team, subscribed: true) }
    it 'help' do
      expect(message: "#{SlackRubyBot.config.user} help").to respond_with_slack_message(
        SlackSup::Commands::Help::HELP
      )
    end
  end
  context 'non-subscribed team after trial' do
    let!(:team) { Fabricate(:team, created_at: 2.weeks.ago) }
    it 'help' do
      expect(message: "#{SlackRubyBot.config.user} help").to respond_with_slack_message([
        SlackSup::Commands::Help::HELP,
        team.trial_message
      ].join("\n"))
    end
  end
  context 'non-subscribed team during trial' do
    let!(:team) { Fabricate(:team, created_at: 1.day.ago) }
    it 'help' do
      expect(message: "#{SlackRubyBot.config.user} help").to respond_with_slack_message([
        SlackSup::Commands::Help::HELP,
        team.trial_message
      ].join("\n"))
    end
  end
end
