module Api
  module Presenters
    module BasePresenter
      extend ActiveSupport::Concern

      def base_url(opts)
        return unless opts.key?(:env)

        request = Grape::Request.new(opts[:env])
        request.base_url
      end

      def request_url(opts)
        return unless opts.key?(:env)

        request = Grape::Request.new(opts[:env])
        "#{request.base_url}#{opts[:env]['PATH_INFO']}"
      end
    end
  end
end
