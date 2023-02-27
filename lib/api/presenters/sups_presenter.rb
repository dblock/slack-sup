module Api
  module Presenters
    module SupsPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer
      include Api::Presenters::PaginatedPresenter

      collection :results, extend: SupPresenter, as: :sups, embedded: true
    end
  end
end
