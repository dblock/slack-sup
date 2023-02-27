module Api
  module Endpoints
    class RoundsEndpoint < Grape::API
      format :json
      helpers Api::Helpers::CursorHelpers
      helpers Api::Helpers::SortHelpers
      helpers Api::Helpers::PaginationParameters
      helpers Api::Helpers::AuthHelpers

      namespace :rounds do
        desc "Get a S'Up round."
        params do
          requires :id, type: String, desc: 'Round ID.'
        end
        get ':id' do
          round = Round.find(params[:id]) || error!('Not Found', 404)
          authorize_channel! round.channel
          present round, with: Api::Presenters::RoundPresenter
        end

        desc "Get all the S'Up rounds for a channel."
        params do
          requires :channel_id, type: String, desc: 'Channel ID.'
          use :pagination
        end
        get do
          channel = Channel.find(params[:channel_id]) || error!('Not Found', 404)
          authorize_channel! channel
          rounds = paginate_and_sort_by_cursor(channel.rounds, default_sort_order: '_id')
          present rounds, with: Api::Presenters::RoundsPresenter
        end
      end
    end
  end
end
