module Api
  module Endpoints
    class SubscriptionsEndpoint < Grape::API
      format :json

      namespace :subscriptions do
        desc 'Subscribe to slack-sup.'
        params do
          requires :stripe_token, type: String
          requires :stripe_token_type, type: String
          requires :stripe_email, type: String
          requires :team_id, type: String
        end
        post do
          team = Team.where(team_id: params[:team_id]).first || error!('Team Not Found', 404)
          Api::Middleware.logger.info "Creating a subscription for team #{team}."
          error!('Already Subscribed', 400) if team.subscribed?
          error!('Customer Already Registered', 400) if team.stripe_customer_id
          customer = team.subscribe!(params)
          Api::Middleware.logger.info "Subscription for team #{team} created, stripe_customer_id=#{customer['id']}."
          present team, with: Api::Presenters::TeamPresenter
        end
      end
    end
  end
end
