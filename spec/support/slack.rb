RSpec.shared_context :client do
  let(:app) { SlackSup::Server.new(team: team) }
  let(:client) { app.send(:client) }
end

RSpec.shared_context :subscribed_team do
  include_context :client
  let!(:team) { Fabricate(:team, subscribed: true) }
end

RSpec.shared_context :team do
  include_context :client
  let!(:team) { Fabricate(:team) }
end

RSpec.shared_context :channel do
  include_context :subscribed_team
  let!(:channel) { Fabricate(:channel, channel_id: 'channel') }
end

RSpec.shared_context :user do
  include_context :channel

  let!(:user) { Fabricate(:user, channel: channel, user_name: 'username') }
end
