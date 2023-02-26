module Api
  module Endpoints
    class SupsEndpoint < Grape::API
      format :json
      helpers Api::Helpers::CursorHelpers
      helpers Api::Helpers::SortHelpers
      helpers Api::Helpers::PaginationParameters
      helpers Api::Helpers::AuthHelpers

      namespace :sups do
        desc "Get a S'Up."
        params do
          requires :id, type: String, desc: 'Sup ID.'
        end
        get ':id' do
          sup = Sup.find(params[:id]) || error!('Not Found', 404)
          authorize_channel! sup.round.channel
          present sup, with: Api::Presenters::SupPresenter
        end

        desc "Update a S'Up."
        params do
          requires :id, type: String, desc: 'Sup ID.'
          requires :gcal_html_link, type: String, desc: 'GCal HTML link.'
        end
        put ':id' do
          sup = Sup.find(params[:id]) || error!('Not Found', 404)
          authorize_short_lived_token! sup.channel
          sup.update_attributes!(gcal_html_link: params[:gcal_html_link])
          present sup, with: Api::Presenters::SupPresenter
        end

        desc "Get all the S'Up for a round."
        params do
          requires :round_id, type: String, desc: 'Round ID.'
          use :pagination
        end
        get do
          round = Round.find(params[:round_id]) || error!('Not Found', 404)
          authorize_channel! round.channel
          sups = paginate_and_sort_by_cursor(round.sups, default_sort_order: '_id')
          present sups, with: Api::Presenters::SupsPresenter
        end
      end
    end
  end
end
