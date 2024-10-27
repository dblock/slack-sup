module Api
  module Endpoints
    class StatsEndpoint < Grape::API
      format :json

      helpers Api::Helpers::AuthHelpers

      namespace :stats do
        desc 'Get stats.'
        params do
          optional :team_id, type: String, desc: 'Optional team ID.'
          optional :round_id, type: String, desc: 'Optional round ID.'
        end
        get do
          if params[:team_id]
            team = Team.where(_id: params[:team_id], api: true).first || error!('Not Found', 404)
            authorize! team
            present Stats.new(team), with: Api::Presenters::TeamStatsPresenter
          elsif params[:round_id]
            round = Round.where(_id: params[:round_id]).first || error!('Not Found', 404)
            authorize! round.team
            present round.stats, with: Api::Presenters::RoundStatsPresenter
          else
            present Stats.new, with: Api::Presenters::StatsPresenter
          end
        end
      end
    end
  end
end
