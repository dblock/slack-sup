module Api
  module Presenters
    module ChannelsPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer
      include Api::Presenters::PaginatedPresenter

      collection :results, extend: ChannelPresenter, as: :channels, embedded: true
    end
  end
end
