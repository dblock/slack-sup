require 'spec_helper'

describe SlackSup::Commands::Rounds do
  let(:team) { Fabricate(:team, subscribed: true) }
  let(:app) { SlackSup::Server.new(team:) }
  let(:client) { app.send(:client) }

  it 'empty stats' do
    expect(message: "#{SlackRubyBot.config.user} rounds").to respond_with_slack_message(
      "Team S'Up facilitated 0 rounds."
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
        "* in progress: 1 S'Up paired 3 users and no outcomes reported.\n" \
        "* 2 years ago: 1 S'Up paired 3 users, 100% positive outcomes and 100% outcomes reported."
      )
    end
  end

  context 'with opt outs, misses, and vacations' do
    let!(:user1) { Fabricate(:user, team:) }
    let!(:user2) { Fabricate(:user, team:) }
    let!(:user3) { Fabricate(:user, team:) }
    let!(:user4) { Fabricate(:user, team:, opted_in: false) }
    let!(:user5) { Fabricate(:user, team:, enabled: false) }
    let!(:user6) { Fabricate(:user, team:) }
    let!(:user7) { Fabricate(:user, team:) }
    let!(:user8) { Fabricate(:user, team:, vacation: true) }

    before do
      team.update_attributes!(sup_odd: false)
      allow(team).to receive(:sync!)
      allow_any_instance_of(Sup).to receive(:dm!)
      team.sup!
    end

    it 'reports counts' do
      expect(message: "#{SlackRubyBot.config.user} rounds 2").to respond_with_slack_message(
        "Team S'Up facilitated 1 round.\n" \
        "* in progress: 1 S'Up paired 3 users, no outcomes reported, 1 opt out, 2 missed users and 1 user on vacation."
      )
    end
  end
end
