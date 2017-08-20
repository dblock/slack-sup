require 'spec_helper'

describe Api::Endpoints::UsersEndpoint do
  include Api::Test::EndpointTest

  let!(:team) { Fabricate(:team, api: true) }

  before do
    @cursor_params = { team_id: team.id.to_s }
  end

  it_behaves_like 'a cursor api', User

  context 'user' do
    let(:existing_user) { Fabricate(:user, team: team) }
    it 'returns a user' do
      user = client.user(id: existing_user.id)
      expect(user.id).to eq existing_user.id.to_s
      expect(user.user_name).to eq existing_user.user_name
      expect(user._links.self._url).to eq "http://example.org/api/users/#{existing_user.id}"
    end
    it 'cannot return a user for a team with api off' do
      team.update_attributes!(api: false)
      expect { client.user(id: existing_user.id).resource }.to raise_error Faraday::ClientError do |e|
        json = JSON.parse(e.response[:body])
        expect(json['error']).to eq 'Not Found'
      end
    end
  end

  context 'users' do
    let!(:user_1) { Fabricate(:user, team: team) }
    let!(:user_2) { Fabricate(:user, team: team) }
    it 'cannot return users for a team with api off' do
      team.update_attributes!(api: false)
      expect { client.users(team_id: team.id).resource }.to raise_error Faraday::ClientError do |e|
        json = JSON.parse(e.response[:body])
        expect(json['error']).to eq 'Not Found'
      end
    end
    it 'returns users' do
      users = client.users(team_id: team.id)
      expect(users.map(&:id).sort).to eq [user_1, user_2].map(&:id).map(&:to_s).sort
    end
  end
end
