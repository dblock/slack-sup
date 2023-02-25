module Api
  module Endpoints
    class StatsEndpoint < Grape::API
      format :json

      helpers Api::Helpers::AuthHelpers

      namespace :stats do
        desc 'Get stats.'
        params do
          optional :team_id, type: String, desc: 'Optional team ID.'
          optional :channel_id, type: String, desc: 'Optional channel ID.'
          mutually_exclusive :channel_id, :team_id
        end
        get do
          if params[:team_id]
            team = Team.where(_id: params[:team_id], api: true).first || error!('Not Found', 404)
            authorize! team
            present TeamStats.new(team), with: Api::Presenters::TeamStatsPresenter
          elsif params[:channel_id]
            channel = Channel.where(_id: params[:channel_id], api: true).first || error!('Not Found', 404)
            authorize! channel
            present ChannelStats.new(channel), with: Api::Presenters::ChannelStatsPresenter
          else
            present Stats.new, with: Api::Presenters::StatsPresenter
          end
        end
      end
    end
  end
end
