module Api
  module Presenters
    module ChannelPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer

      property :id, type: String, desc: 'Channel ID.'
      property :enabled, type: Grape::API::Boolean, desc: 'Channel is enabled.'
      property :channel_id, type: String, desc: 'Slack channel ID.'
      property :created_at, type: DateTime, desc: 'Date/time when the channel was created.'
      property :updated_at, type: DateTime, desc: 'Date/time when the channel was updated.'
      property :sup_wday, type: Integer, desc: "S'Up day of the week."
      property :sup_followup_wday, type: Integer, desc: "Ask for S'up result day of week."
      property :sup_day, type: String, desc: "S'Up day of the week in English."
      property :sup_tz, type: String, desc: 'Channel timezone.'
      property :sup_time_of_day, type: String, desc: "Earliest time of day for a S'Up in seconds."
      property :sup_time_of_day_s, type: String, desc: "Earliest time of day for a S'Up."
      property :sup_every_n_weeks, type: Integer, desc: "Frequency of S'Up in weeks."
      property :sup_size, type: Integer, desc: "The number of people that meet for each S'Up."

      link :team do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/api/teams/#{team.id}"
      end

      link :users do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/api/users?channel_id=#{id}"
      end

      link :rounds do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/api/rounds?channel_id=#{id}"
      end

      link :stats do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/api/stats?channel_id=#{id}"
      end

      link :self do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/api/channels/#{id}"
      end
    end
  end
  end
