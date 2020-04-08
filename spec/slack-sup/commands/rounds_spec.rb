require 'spec_helper'

describe SlackSup::Commands::Rounds do
  let(:team) { Fabricate(:team, subscribed: true) }
  let(:app) { SlackSup::Server.new(team: team) }
  let(:client) { app.send(:client) }
  it 'empty stats' do
    expect(message: "#{SlackRubyBot.config.user} rounds").to respond_with_slack_message(
      "Team S'Up facilitated 0 rounds."
    )
  end
  context 'with outcomes' do
    let(:team) { Fabricate(:team, subscribed: true) }
    let!(:user1) { Fabricate(:user, team: team) }
    let!(:user2) { Fabricate(:user, team: team) }
    let!(:user3) { Fabricate(:user, team: team) }
    before do
      allow(team).to receive(:sync!)
      allow_any_instance_of(Sup).to receive(:dm!)
      Timecop.freeze do
        round = team.sup!
        round.ask!
        Sup.asc(:_id).first.update_attributes!(outcome: 'all')
        Timecop.travel(Time.now + 1.year)
        team.sup!
      end
    end
    it 'reports counts' do
      Timecop.travel(Time.now + 731.days)
      expect(message: "#{SlackRubyBot.config.user} rounds 2").to respond_with_slack_message(
        "Team S'Up facilitated 2 rounds.\n" \
        "* in progress: 1 S'Up for 3 users with 0% positive outcomes from 0% outcomes reported.\n" \
        "* 731 days ago: 1 S'Up for 3 users with 100% positive outcomes from 100% outcomes reported."
      )
    end
  end
end
