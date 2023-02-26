module Api
  module Endpoints
    class ChannelsEndpoint < Grape::API
      format :json
      helpers Api::Helpers::CursorHelpers
      helpers Api::Helpers::SortHelpers
      helpers Api::Helpers::PaginationParameters
      helpers Api::Helpers::AuthHelpers

      namespace :channels do
        desc 'Get a channel.'
        params do
          requires :id, type: String, desc: 'Channel ID.'
        end
        get ':id' do
          channel = Channel.find(_id: params[:id]) || error!('Not Found', 404)
          authorize_channel! channel
          present channel, with: Api::Presenters::ChannelPresenter
        end

        desc 'Get all the channels for a team.'
        params do
          requires :team_id, type: String, desc: 'Team ID.'
          use :pagination
        end
        get do
          team = Team.find(params[:team_id]) || error!('Not Found', 404)
          authorize_team! team
          channels = paginate_and_sort_by_cursor(team.channels, default_sort_order: '-_id')
          present channels, with: Api::Presenters::ChannelsPresenter
        end
      end
    end
  end
end
