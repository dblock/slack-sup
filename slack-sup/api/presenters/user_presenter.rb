module Api
  module Presenters
    module UserPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer
      include BasePresenter

      property :id, type: String, desc: 'User ID.'
      property :user_id, type: String, desc: 'Slack user ID.'
      property :user_name, type: String, desc: 'Slack user name.'
      property :real_name, type: String, desc: 'Slack real name.'
      property :custom_team_name, type: String, desc: 'Custom team name from the user profile.'
      property :is_admin, type: Grape::API::Boolean, desc: 'User is an admin.'
      property :enabled, type: Grape::API::Boolean, desc: 'User is enabled.'
      property :opted_in, type: Grape::API::Boolean, desc: "User is opted into S'Up."
      property :created_at, type: DateTime, desc: 'Date/time when the user was created.'
      property :updated_at, type: DateTime, desc: 'Date/time when the user was updated.'

      link :team do |opts|
        "#{base_url(opts)}/api/teams/#{team_id}"
      end

      link :self do |opts|
        "#{base_url(opts)}/api/users/#{id}"
      end
    end
  end
end
