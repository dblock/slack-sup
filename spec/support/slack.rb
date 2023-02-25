RSpec.shared_context :client do
  let(:app) { SlackSup::Server.new(team: team) }
  let(:client) { app.send(:client) }
end

RSpec.shared_context :team do
  include_context :client
  let!(:team) { Fabricate(:team, subscribed: true) }
end

RSpec.shared_context :channel do
  include_context :team
  let!(:channel) { Fabricate(:channel, channel_id: 'channel') }
end
