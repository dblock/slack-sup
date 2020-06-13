module Api
  module Presenters
    module RoundPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer

      property :id, type: String, desc: 'Round ID.'
      property :total_users_count, desc: 'Total users.'
      property :opted_in_users_count, desc: 'Total users opted in.'
      property :opted_out_users_count, desc: 'Total users opted out'
      property :paired_users_count, desc: 'Total users paired.'
      property :missed_users_count, desc: 'Total users not paired.'
      property :ran_at, type: DateTime, desc: 'Date/time when the round was run.'
      property :asked_at, type: DateTime, desc: 'Date/time when outcomes were collected.'
      property :created_at, type: DateTime, desc: 'Date/time when the round was created.'
      property :updated_at, type: DateTime, desc: 'Date/time when the round was updated.'

      link :team do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/api/teams/#{team_id}"
      end

      link :sups do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/api/sups?round_id=#{id}"
      end

      link :self do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/api/rounds/#{id}"
      end
    end
  end
end
