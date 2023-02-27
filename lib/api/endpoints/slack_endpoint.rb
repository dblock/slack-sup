module Api
  module Endpoints
    class SlackEndpoint < Grape::API
      namespace :slack do
        format :json

        before do
          ::Slack::Events::Request.new(
            request,
            signing_secret: SlackRubyBotServer::Events.config.signing_secret,
            signature_expires_in: SlackRubyBotServer::Events.config.signature_expires_in
          ).verify!
        rescue ::Slack::Events::Request::TimestampExpired
          error!('Invalid Signature', 403)
        end

        mount SlackRubyBotServer::Events::Api::Endpoints::Slack::CommandsEndpoint
        mount SlackRubyBotServer::Events::Api::Endpoints::Slack::ActionsEndpoint
        mount SlackRubyBotServer::Events::Api::Endpoints::Slack::EventsEndpoint
      end
    end
  end
end
