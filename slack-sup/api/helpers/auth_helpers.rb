module Api
  module Helpers
    module AuthHelpers
      def authorize_short_lived_token!(team)
        jwt_token = headers['X-Access-Token']
        error!('Access Denied', 401) unless team.short_lived_token_valid?(jwt_token)
      end

      def authorize!(team)
        access_token = headers['X-Access-Token']
        error!('Not Found', 404) unless team.api?
        error!('Access Denied', 401) unless team.api_token == access_token
      end
    end
  end
end
