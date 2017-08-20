require 'spec_helper'

describe Api::Endpoints::SupsEndpoint do
  include Api::Test::EndpointTest

  let!(:team) { Fabricate(:team, api: true) }
  let!(:round) { Fabricate(:round, team: team) }

  before do
    @cursor_params = { round_id: round.id.to_s }
  end

  it_behaves_like 'a cursor api', Sup

  context 'sup' do
    let(:existing_sup) { Fabricate(:sup, round: round) }
    it 'returns a sup' do
      sup = client.sup(id: existing_sup.id)
      expect(sup.id).to eq existing_sup.id.to_s
      expect(sup._links.self._url).to eq "http://example.org/api/sups/#{existing_sup.id}"
    end
    it 'cannot return a sup for a team with api off' do
      team.update_attributes!(api: false)
      expect { client.sup(id: existing_sup.id).resource }.to raise_error Faraday::ClientError do |e|
        json = JSON.parse(e.response[:body])
        expect(json['error']).to eq 'Not Found'
      end
    end
  end

  context 'sups' do
    let!(:sup_1) { Fabricate(:sup, round: round) }
    let!(:sup_2) { Fabricate(:sup, round: round) }
    it 'cannot return sups for a team with api off' do
      team.update_attributes!(api: false)
      expect { client.sups(round_id: round.id).resource }.to raise_error Faraday::ClientError do |e|
        json = JSON.parse(e.response[:body])
        expect(json['error']).to eq 'Not Found'
      end
    end
    it 'returns sups' do
      sups = client.sups(round_id: round.id)
      expect(sups.map(&:id).sort).to eq [sup_1, sup_2].map(&:id).map(&:to_s).sort
    end
  end
end
