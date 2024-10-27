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
    let!(:user1) { Fabricate(:user, team:) }
    let!(:user2) { Fabricate(:user, team:) }
    let!(:user3) { Fabricate(:user, team:) }

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

    it 'reports counts for a team' do
      stats = client.stats(team_id: team.id)
      expect(stats.rounds_count).to eq 2
      expect(stats.sups_count).to eq 2
      expect(stats.users_in_sups_count).to eq 3
      expect(stats.users_opted_in_count).to eq 3
      expect(stats.users_count).to eq 3
      expect(stats.outcomes).to eq('all' => 1, 'unknown' => 1)
    end

    it 'reports counts for another team' do
      stats = client.stats(team_id: Fabricate(:team).id)
      expect(stats.rounds_count).to eq 0
      expect(stats.sups_count).to eq 0
      expect(stats.users_in_sups_count).to eq 0
      expect(stats.users_opted_in_count).to eq 0
      expect(stats.users_count).to eq 0
      expect(stats.outcomes).to eq({})
    end

    context 'a team with an api token' do
      before do
        team.update_attributes!(api_token: 'token')
      end

      it 'cannot return stats without a token' do
        expect { client.stats(team_id: team.id).resource }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['error']).to eq 'Access Denied'
        end
      end

      it 'cannot return stats with an invalid a token' do
        client.headers.update('X-Access-Token' => 'invalid')
        expect { client.stats(team_id: team.id).resource }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['error']).to eq 'Access Denied'
        end
      end

      it 'returns a stats' do
        client.headers.update('X-Access-Token' => 'token')
        stats = client.stats(team_id: team.id)
        expect(stats.sups_count).to eq 2
      end
    end

    context 'round' do
      let(:round) { team.rounds.last }

      it 'reports counts for a round' do
        stats = client.stats(round_id: round.id)
        expect(stats.positive_outcomes_count).to eq 0
        expect(stats.reported_outcomes_count).to eq 0
      end

      it 'reports counts for another round' do
        stats = client.stats(round_id: Fabricate(:round).id)
        expect(stats.positive_outcomes_count).to eq 0
        expect(stats.reported_outcomes_count).to eq 0
      end

      context 'with a team api token' do
        before do
          client.headers.update('X-Access-Token' => 'token')
          team.update_attributes!(api_token: 'token')
        end

        it 'returns stats' do
          stats = client.stats(round_id: round.id)
          round.sups.last.update_attributes!(outcome: 'all')
          expect(stats.positive_outcomes_count).to eq 1
          expect(stats.reported_outcomes_count).to eq 1
        end
      end
    end
  end
end
