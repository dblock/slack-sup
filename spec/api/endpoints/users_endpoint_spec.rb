require 'spec_helper'

describe Api::Endpoints::UsersEndpoint do
  include Api::Test::EndpointTest

  let!(:channel) { Fabricate(:channel, api: true) }

  before do
    @cursor_params = { channel_id: channel.id.to_s }
  end

  it_behaves_like 'a cursor api', User
  it_behaves_like 'a channel token api', User

  context 'user' do
    let(:existing_user) { Fabricate(:user, channel: channel) }
    it 'returns a user' do
      user = client.user(id: existing_user.id)
      expect(user.id).to eq existing_user.id.to_s
      expect(user.user_name).to eq existing_user.user_name
      expect(user._links.self._url).to eq "http://example.org/api/users/#{existing_user.id}"
    end
  end

  context 'users' do
    let!(:user_1) { Fabricate(:user, channel: channel) }
    let!(:user_2) { Fabricate(:user, channel: channel) }
    it 'returns users' do
      users = client.users(channel_id: channel.id)
      expect(users.map(&:id).sort).to eq [user_1, user_2].map(&:id).map(&:to_s).sort
    end
  end
end
