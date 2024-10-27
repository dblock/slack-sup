module Api
  module Presenters
    module StatsPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer
      include BasePresenter

      link :self do |opts|
        "#{base_url(opts)}/api/stats"
      end

      property :teams_count
      property :active_teams_count
      property :rounds_count
      property :sups_count
      property :users_in_sups_count
      property :users_opted_in_count
      property :users_count
      property :outcomes

      def teams_count
        Team.count
      end

      def active_teams_count
        Team.active.count
      end
    end
  end
end
