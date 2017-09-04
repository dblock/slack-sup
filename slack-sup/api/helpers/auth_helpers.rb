module Api
  module Helpers
    module AuthHelpers
      def authorize!(team)
        jwt_token = headers['X-Access-Token']
        error!('Access Denied', 401) unless team.short_lived_token_valid?(jwt_token)
      end
    end
  end
end
