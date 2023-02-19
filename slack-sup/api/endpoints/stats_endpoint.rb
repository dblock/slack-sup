module Api
  module Endpoints
    class StatsEndpoint < Grape::API
      format :json

      helpers Api::Helpers::AuthHelpers

      namespace :stats do
        desc 'Get stats.'
        params do
          optional :channel_id, type: String, desc: 'Optional channel ID.'
        end
        get do
          if params[:channel_id]
            channel = Channel.where(_id: params[:channel_id], api: true).first || error!('Not Found', 404)
            authorize! channel
            present Stats.new(channel), with: Api::Presenters::ChannelStatsPresenter
          else
            present Stats.new, with: Api::Presenters::StatsPresenter
          end
        end
      end
    end
  end
end
