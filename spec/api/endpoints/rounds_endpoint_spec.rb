require 'spec_helper'

describe Api::Endpoints::RoundsEndpoint do
  include Api::Test::EndpointTest

  let!(:team) { Fabricate(:team, api: true, sup_odd: false) }

  before do
    @cursor_params = { team_id: team.id.to_s }
  end

  it_behaves_like 'a cursor api', Round
  it_behaves_like 'a team token api', Round

  context 'round' do
    let(:last_round) { team.rounds.last }

    before do
      4.times { Fabricate(:user, team:) }
      allow(team).to receive(:sync!)
      allow_any_instance_of(Sup).to receive(:dm!)
      team.sup!
    end

    it 'returns a round' do
      round = client.round(id: last_round.id)
      expect(round.id).to eq last_round.id.to_s
      expect(round.paired_users_count).to eq 3
      expect(round.paired_users.length).to eq 3
      expect(round.missed_users_count).to eq 1
      expect(round.missed_users.length).to eq 1
      expect(round.vacation_users_count).to eq 0
      expect(round.vacation_users.length).to eq 0
      expect(round._links.self._url).to eq "http://example.org/api/rounds/#{last_round.id}"
    end
  end

  context 'rounds' do
    let!(:round_1) { Fabricate(:round, team:) }
    let!(:round_2) { Fabricate(:round, team:) }

    it 'returns rounds' do
      rounds = client.rounds(team_id: team.id)
      expect(rounds.map(&:id).sort).to eq [round_1, round_2].map(&:id).map(&:to_s).sort
    end
  end
end
