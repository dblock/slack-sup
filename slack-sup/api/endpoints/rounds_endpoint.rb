module Api
  module Endpoints
    class RoundsEndpoint < Grape::API
      format :json
      helpers Api::Helpers::CursorHelpers
      helpers Api::Helpers::SortHelpers
      helpers Api::Helpers::PaginationParameters

      namespace :rounds do
        desc "Get a S'Up round."
        params do
          requires :id, type: String, desc: 'Round ID.'
        end
        get ':id' do
          round = Round.find(params[:id]) || error!('Not Found', 404)
          error!('Not Found', 404) unless round.team.api?
          present round, with: Api::Presenters::RoundPresenter
        end

        desc "Get all the S'Up rounds for a team."
        params do
          requires :team_id, type: String, desc: 'Team ID.'
          use :pagination
        end
        get do
          team = Team.find(params[:team_id]) || error!('Not Found', 404)
          error!('Not Found', 404) unless team.api?
          rounds = paginate_and_sort_by_cursor(team.rounds, default_sort_order: '_id')
          present rounds, with: Api::Presenters::RoundsPresenter
        end
      end
    end
  end
end
