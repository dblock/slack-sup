module Api
  module Endpoints
    class UsersEndpoint < Grape::API
      format :json
      helpers Api::Helpers::CursorHelpers
      helpers Api::Helpers::SortHelpers
      helpers Api::Helpers::PaginationParameters

      namespace :users do
        desc 'Get a user.'
        params do
          requires :id, type: String, desc: 'User ID.'
        end
        get ':id' do
          user = User.find(params[:id]) || error!('Not Found', 404)
          error!('Not Found', 404) unless user.team.api?
          present user, with: Api::Presenters::UserPresenter
        end

        desc 'Get all the users for a team.'
        params do
          requires :team_id, type: String, desc: 'Team ID.'
          use :pagination
        end
        get do
          team = Team.find(params[:team_id]) || error!('Not Found', 404)
          error!('Not Found', 404) unless team.api?
          users = paginate_and_sort_by_cursor(team.users, default_sort_order: '-_id')
          present users, with: Api::Presenters::UsersPresenter
        end
      end
    end
  end
end
