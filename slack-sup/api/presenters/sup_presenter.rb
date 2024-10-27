module Api
  module Presenters
    module SupPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer
      include BasePresenter

      property :id, type: String, desc: "S'Up ID."
      property :outcome, type: String, desc: "S'up outcome."
      property :captain_user_name, type: String, desc: 'Captain user name.'
      property :created_at, type: DateTime, desc: "Date/time when the S'Up was created."
      property :updated_at, type: DateTime, desc: "Date/time when the S'Up was updated."

      collection :users, extend: UserPresenter, as: :users, embedded: true

      link :captain do |opts|
        next unless captain_id

        "#{base_url(opts)}/api/users/#{captain_id}"
      end

      link :round do |opts|
        "#{base_url(opts)}/api/rounds/#{round_id}"
      end

      link :self do |opts|
        "#{base_url(opts)}/api/sups/#{id}"
      end
    end
  end
end
