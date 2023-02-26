module Api
  module Endpoints
    class UsersEndpoint < Grape::API
      format :json
      helpers Api::Helpers::CursorHelpers
      helpers Api::Helpers::SortHelpers
      helpers Api::Helpers::PaginationParameters
      helpers Api::Helpers::AuthHelpers

      namespace :users do
        desc 'Get a user.'
        params do
          requires :id, type: String, desc: 'User ID.'
        end
        get ':id' do
          user = User.find(params[:id]) || error!('Not Found', 404)
          authorize_channel! user.channel
          present user, with: Api::Presenters::UserPresenter
        end

        desc 'Get all the users for a channel.'
        params do
          requires :channel_id, type: String, desc: 'Channel ID.'
          use :pagination
        end
        get do
          channel = Channel.find(params[:channel_id]) || error!('Not Found', 404)
          authorize_channel! channel
          users = paginate_and_sort_by_cursor(channel.users, default_sort_order: '-_id')
          present users, with: Api::Presenters::UsersPresenter
        end
      end
    end
  end
end
