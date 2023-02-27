module Api
  module Presenters
    module TeamStatsPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer

      link :self do |opts|
        "#{base_url(opts)}/api/stats?team_id=#{team.id}"
      end

      property :rounds_count
      property :sups_count
      property :users_in_sups_count
      property :users_opted_in_count
      property :users_count
      property :channels_count
      property :channels_enabled_count
      property :outcomes

      def base_url(opts)
        request = Grape::Request.new(opts[:env])
        request.base_url
      end
    end
  end
end
