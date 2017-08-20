module Api
  module Presenters
    module RoundPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer

      property :id, type: String, desc: 'Round ID.'
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
