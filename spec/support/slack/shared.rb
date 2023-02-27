RSpec.shared_context :subscribed_team do
  let!(:team) { Fabricate(:team, subscribed: true) }
end

RSpec.shared_context :team do
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
