module Api
  module Presenters
    module UserPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer

      property :id, type: String, desc: 'User ID.'
      property :user_id, type: String, desc: 'Slack user ID.'
      property :user_name, type: String, desc: 'Slack user name.'
      property :real_name, type: String, desc: 'Slack real name.'
      property :is_admin, type: Boolean, desc: 'User is an admin.'
      property :enabled, type: Boolean, desc: 'User is enabled.'
      property :opted_in, type: Boolean, desc: "User is opted into S'Up."
      property :created_at, type: DateTime, desc: 'Date/time when the team was created.'
      property :updated_at, type: DateTime, desc: 'Date/time when the team was accepted, declined or canceled.'

      link :team do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/api/teams/#{team.id}"
      end

      link :self do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/api/users/#{id}"
      end
    end
  end
end
