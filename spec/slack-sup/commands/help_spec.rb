require 'spec_helper'

describe SlackSup::Commands::Help do
  context 'subscribed team' do
    let!(:team) { Fabricate(:team, subscribed: true) }
    it 'help' do
      expect(message: '@sup help').to respond_with_slack_message(
        SlackSup::Commands::Help::HELP
      )
    end
  end
  context 'non-subscribed team after trial' do
    let!(:team) { Fabricate(:team, created_at: 2.weeks.ago) }
    it 'help' do
      expect(message: '@sup help').to respond_with_slack_message([
        SlackSup::Commands::Help::HELP,
        team.trial_message
      ].join("\n"))
    end
  end
  context 'non-subscribed team during trial' do
    let!(:team) { Fabricate(:team, created_at: 1.day.ago) }
    it 'help' do
      expect(message: '@sup help').to respond_with_slack_message([
        SlackSup::Commands::Help::HELP,
        team.trial_message
      ].join("\n"))
    end
  end
end
