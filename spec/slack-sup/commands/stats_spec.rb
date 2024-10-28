require 'spec_helper'

describe SlackSup::Commands::Stats do
  let(:team) { Fabricate(:team, sup_wday: Date::MONDAY, subscribed: true) }
  let(:app) { SlackSup::Server.new(team:) }
  let(:client) { app.send(:client) }

  it 'empty stats' do
    expect(message: "#{SlackRubyBot.config.user} stats").to respond_with_slack_message(
      "Team S'Up connects groups of 3 people on Monday after 9:00 AM every week.\n" \
      "Team S'Up started 3 weeks ago with no users (0/0) opted in."
    )
  end

  context 'with outcomes' do
    let!(:user1) { Fabricate(:user, team:) }
    let!(:user2) { Fabricate(:user, team:) }
    let!(:user3) { Fabricate(:user, team:) }

    before do
      allow(team).to receive(:sync!)
      allow_any_instance_of(Sup).to receive(:dm!)
      Timecop.freeze do
        team.sup!
        Timecop.travel(Time.now + 1.year)
        team.sup!
      end
      Sup.first.update_attributes!(outcome: 'all')
      user2.update_attributes!(opted_in: false)
    end

    it 'reports counts' do
      expect(message: "#{SlackRubyBot.config.user} stats").to respond_with_slack_message(
        "Team S'Up connects groups of 3 people on Monday after 9:00 AM every week.\n" \
        "Team S'Up started 3 weeks ago with 66% (2/3) of users opted in.\n" \
        "Facilitated 2 S'Ups in 2 rounds for 3 users with 50% positive outcomes from 50% outcomes reported."
      )
    end
  end
end
