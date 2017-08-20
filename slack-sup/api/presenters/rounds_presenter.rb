module Api
  module Presenters
    module RoundsPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer
      include Api::Presenters::PaginatedPresenter

      collection :results, extend: RoundPresenter, as: :rounds, embedded: true
    end
  end
end
