module Api
  module Endpoints
    class DataEndpoint < Grape::API
      format :binary
      helpers Api::Helpers::AuthHelpers

      namespace :data do
        desc 'Get data.'
        params do
          requires :id, type: String, desc: 'Export ID.'
        end
        get ':id' do
          data = Export.find(_id: params[:id]) || error!('Data Not Found', 404)
          authorize_short_lived_token! data.team
          error!('Data Not Ready', 404) unless data.exported?
          error!('Data Expired', 404) unless File.exist?(data.filename)
          Api::Middleware.logger.info "Sending #{ByteSize.new(File.size(data.filename))} data file for #{data.team}."
          content_type 'application/zip'
          header['Content-Disposition'] = "attachment; filename=#{File.basename(data.filename)}"
          File.binread data.filename
        end
      end
    end
  end
end
