module Api
  module Presenters
    module RoundPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer
      include BasePresenter

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
        "#{base_url(opts)}/api/teams/#{team_id}"
      end

      link :stats do |opts|
        "#{base_url(opts)}/api/stats?round_id=#{id}"
      end

      link :sups do |opts|
        "#{base_url(opts)}/api/sups?round_id=#{id}"
      end

      link :self do |opts|
        "#{base_url(opts)}/api/rounds/#{id}"
      end
    end
  end
end
