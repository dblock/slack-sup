require 'spec_helper'

describe Api::Endpoints::StatusEndpoint do
  include Api::Test::EndpointTest

  before do
    allow_any_instance_of(Team).to receive(:ping!).and_return(ok: 1)
  end

  context 'status' do
    context 'with a team' do
      let!(:team) { Fabricate(:team) }
      it 'returns a status with ping' do
        status = client.status
        ping = status.ping
        expect(ping['ok']).to eq 1
      end
    end
  end
end
