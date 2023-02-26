require 'spec_helper'

describe Stats do
  include_context :subscribed_team
  let(:stats) { TeamStats.new(team) }
  it 'reports counts' do
    expect(stats.rounds_count).to eq 0
    expect(stats.sups_count).to eq 0
    expect(stats.users_count).to eq 0
    expect(stats.users_opted_in_count).to eq 0
    expect(stats.positive_outcomes_count).to eq 0
    expect(stats.reported_outcomes_count).to eq 0
    expect(stats.outcomes).to eq({})
    expect(stats.team).to eq team
    expect(stats.to_s).to eq "Team S'Up connects 0 users in 0 channels."
  end
  context 'with outcomes' do
    include_context :subscribed_team

    let!(:channel1) { Fabricate(:channel, team: team) }
    let!(:channel1_user1) { Fabricate(:user, channel: channel1) }
    let!(:channel1_user2) { Fabricate(:user, channel: channel1, user_id: 'slack1') }
    let!(:channel1_user3) { Fabricate(:user, channel: channel1) }
    let!(:channel2) { Fabricate(:channel, team: team) }
    let!(:channel2_user1) { Fabricate(:user, channel: channel2) }
    let!(:channel2_user2) { Fabricate(:user, channel: channel2, user_id: 'slack1') }
    let!(:channel2_user3) { Fabricate(:user, channel: channel2, opted_in: false) }
    let!(:channel3) { Fabricate(:channel, team: Fabricate(:team)) }
    let!(:channel3_user1) { Fabricate(:user, channel: channel3) }
    let!(:channel3_user2) { Fabricate(:user, channel: channel3, user_id: 'slack1') }
    let!(:channel3_user3) { Fabricate(:user, channel: channel3) }
    before do
      allow_any_instance_of(Channel).to receive(:sync!)
      allow_any_instance_of(Sup).to receive(:dm!)
      2.times do
        channel1.sup!
        channel2.sup!
        channel3.sup!
        Timecop.travel(Time.now + 1.year)
      end
      Sup.first.update_attributes!(outcome: 'all')
    end
    it 'reports counts' do
      expect(stats.rounds_count).to eq 4
      expect(stats.sups_count).to eq 4
      expect(stats.users_count).to eq 5
      expect(stats.users_opted_in_count).to eq 4
      expect(stats.positive_outcomes_count).to eq 1
      expect(stats.reported_outcomes_count).to eq 1
      expect(stats.outcomes).to eq(all: 1, unknown: 3)
      expect(stats.team).to eq team
      expect(stats.to_s).to eq [
        "Team S'Up connects 4 users in 2 channels (#{channel1.slack_mention} and #{channel2.slack_mention}).",
        "Team S'Up has 80% (4/5) of users opted in.",
        "Facilitated 4 S'Ups in 4 rounds for 5 users with 25% positive outcomes from 25% outcomes reported."
      ].join("\n")
    end
  end
end
