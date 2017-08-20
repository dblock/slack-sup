module Api
  module Presenters
    module SupPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer

      property :id, type: String, desc: "S'Up ID."
      property :outcome, type: String, desc: "S'up outcome."
      property :created_at, type: DateTime, desc: "Date/time when the S'Up was created."
      property :updated_at, type: DateTime, desc: "Date/time when the S'Up was updated."

      collection :users, extend: UserPresenter, as: :users, embedded: true

      link :round do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/api/rounds/#{round_id}"
      end

      link :self do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/api/sups/#{id}"
      end
    end
  end
end
