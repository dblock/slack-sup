module Api
  module Presenters
    module RoundStatsPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer
      include BasePresenter

      link :self do |opts|
        next unless opts.key?(:env)

        "#{base_url(opts)}/api/stats?round_id=#{round.id}"
      end

      property :positive_outcomes_count
      property :reported_outcomes_count

      link :round do |opts|
        "#{base_url(opts)}/api/rounds/#{round.id}"
      end

      link :team do |opts|
        "#{base_url(opts)}/api/teams/#{round.team.id}"
      end
    end
  end
end
