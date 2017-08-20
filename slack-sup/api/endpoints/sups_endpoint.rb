module Api
  module Endpoints
    class SupsEndpoint < Grape::API
      format :json
      helpers Api::Helpers::CursorHelpers
      helpers Api::Helpers::SortHelpers
      helpers Api::Helpers::PaginationParameters

      namespace :sups do
        desc "Get a S'Up."
        params do
          requires :id, type: String, desc: 'Sup ID.'
        end
        get ':id' do
          sup = Sup.find(params[:id]) || error!('Not Found', 404)
          error!('Not Found', 404) unless sup.round.team.api?
          present sup, with: Api::Presenters::SupPresenter
        end

        desc "Get all the S'Up for a round."
        params do
          requires :round_id, type: String, desc: 'Team ID.'
          use :pagination
        end
        get do
          round = Round.find(params[:round_id]) || error!('Not Found', 404)
          error!('Not Found', 404) unless round.team.api?
          sups = paginate_and_sort_by_cursor(round.sups, default_sort_order: '_id')
          present sups, with: Api::Presenters::SupsPresenter
        end
      end
    end
  end
end
