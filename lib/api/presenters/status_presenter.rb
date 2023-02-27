module Api
  module Presenters
    module StatusPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer

      link :self do |opts|
        "#{base_url(opts)}/api/status"
      end

      property :ping

      def ping
        team = Team.active.asc(:_id).first
        return unless team

        team.ping!
      end

      def base_url(opts)
        request = Grape::Request.new(opts[:env])
        request.base_url
      end
    end
  end
end
