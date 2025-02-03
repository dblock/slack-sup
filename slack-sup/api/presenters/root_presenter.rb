module Api
  module Presenters
    module RootPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer
      include BasePresenter

      link :self do |opts|
        "#{base_url(opts)}/api"
      end

      link :status do |opts|
        "#{base_url(opts)}/api/status"
      end

      link :subscriptions do |opts|
        "#{base_url(opts)}/api/subscriptions"
      end

      link :credit_cards do |opts|
        "#{base_url(opts)}/api/credit_cards"
      end

      link :teams do |opts|
        {
          href: "#{base_url(opts)}/api/teams/#{link_params(Api::Helpers::PaginationParameters::ALL, :active)}",
          templated: true
        }
      end

      link :users do |opts|
        {
          href: "#{base_url(opts)}/api/users/#{link_params(Api::Helpers::PaginationParameters::ALL, :team_id)}",
          templated: true
        }
      end

      link :rounds do |opts|
        {
          href: "#{base_url(opts)}/api/rounds/#{link_params(Api::Helpers::PaginationParameters::ALL, :team_id)}",
          templated: true
        }
      end

      link :sups do |opts|
        {
          href: "#{base_url(opts)}/api/sups/#{link_params(Api::Helpers::PaginationParameters::ALL, :round_id)}",
          templated: true
        }
      end

      link :stats do |opts|
        {
          href: "#{base_url(opts)}/api/stats/{?round_id,team_id}",
          templated: true
        }
      end

      %i[user team round sup data].each do |model|
        link model do |opts|
          {
            href: "#{base_url(opts)}/api/#{model.to_s.pluralize}/{id}",
            templated: true
          }
        end
      end

      private

      def link_params(*args)
        "{?#{args.join(',')}}"
      end
    end
  end
end
