module Api
  module Endpoints
    class StatsEndpoint < Grape::API
      format :json

      namespace :stats do
        desc 'Get stats.'
        params do
          optional :team_id, type: String, desc: 'Optional team ID.'
        end
        get do
          if params[:team_id]
            team = Team.where(_id: params[:team_id], api: true).first || error!('Not Found', 404)
            present Stats.new(team), with: Api::Presenters::TeamStatsPresenter
          else
            present Stats.new, with: Api::Presenters::StatsPresenter
          end
        end
      end
    end
  end
end
