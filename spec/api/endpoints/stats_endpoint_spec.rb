require 'spec_helper'

describe Api::Endpoints::StatsEndpoint do
  include Api::Test::EndpointTest

  context 'global' do
    it 'reports counts' do
      stats = client.stats
      expect(stats.teams_count).to eq 0
      expect(stats.rounds_count).to eq 0
      expect(stats.sups_count).to eq 0
      expect(stats.users_in_sups_count).to eq 0
      expect(stats.users_opted_in_count).to eq 0
      expect(stats.users_count).to eq 0
      expect(stats.outcomes).to eq({})
    end
  end
  context 'team with outcomes' do
    let(:team) { Fabricate(:team) }
    let!(:user1) { Fabricate(:user, team: team) }
    let!(:user2) { Fabricate(:user, team: team) }
    let!(:user3) { Fabricate(:user, team: team) }
    before do
      allow(team).to receive(:sync!)
      allow_any_instance_of(Sup).to receive(:dm!)
      2.times do
        team.sup!
        Timecop.travel(Time.now + 1.year)
      end
      Sup.first.update_attributes!(outcome: 'all')
    end
    it 'reports counts' do
      stats = client.stats
      expect(stats.rounds_count).to eq 2
      expect(stats.sups_count).to eq 2
      expect(stats.users_in_sups_count).to eq 3
      expect(stats.users_opted_in_count).to eq 3
      expect(stats.users_count).to eq 3
      expect(stats.outcomes).to eq('all' => 1, 'unknown' => 1)
    end
  end
end
