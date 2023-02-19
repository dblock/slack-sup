module Api
  module Helpers
    module AuthHelpers
      def authorize_short_lived_token!(channel)
        jwt_token = headers['X-Access-Token']
        error!('Access Denied', 401) unless channel.short_lived_token_valid?(jwt_token)
      end

      def authorize!(channel_or_team)
        access_token = headers['X-Access-Token']
        error!('Not Found', 404) unless channel_or_team.api?
        error!('Access Denied', 401) unless channel_or_team.api_token == access_token
      end
    end
  end
end
