require 'spec_helper'

describe Api::Endpoints::RoundsEndpoint do
  include Api::Test::EndpointTest

  let!(:team) { Fabricate(:team, api: true) }

  before do
    @cursor_params = { team_id: team.id.to_s }
  end

  it_behaves_like 'a cursor api', Round
  it_behaves_like 'a team token api', Round

  context 'round' do
    let(:existing_round) { Fabricate(:round, team: team) }
    it 'returns a round' do
      round = client.round(id: existing_round.id)
      expect(round.id).to eq existing_round.id.to_s
      expect(round._links.self._url).to eq "http://example.org/api/rounds/#{existing_round.id}"
    end
  end

  context 'rounds' do
    let!(:round_1) { Fabricate(:round, team: team) }
    let!(:round_2) { Fabricate(:round, team: team) }
    it 'returns rounds' do
      rounds = client.rounds(team_id: team.id)
      expect(rounds.map(&:id).sort).to eq [round_1, round_2].map(&:id).map(&:to_s).sort
    end
  end
end
