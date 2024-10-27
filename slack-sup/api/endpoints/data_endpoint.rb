module Api
  module Endpoints
    class DataEndpoint < Grape::API
      format :binary
      helpers Api::Helpers::AuthHelpers

      namespace :data do
        desc 'Get data.'
        params do
          requires :team_id, type: String, desc: 'Required team ID.'
        end
        get do
          team = Team.find(_id: params[:team_id]) || error!('Team Not Found', 404)

          authorize_short_lived_token! team

          path = File.join(Dir.tmpdir, 'slack-sup2', team.id)
          filename = team.export_filename(path)

          if !File.exist?(filename) || (File.mtime(filename) + 1.hour < Time.now)
            FileUtils.rm_rf(path)
            FileUtils.makedirs(path)
            Api::Middleware.logger.info "Generating data file for #{team}."
            filename = team.export_zip!(path)
          end

          Api::Middleware.logger.info "Sending #{ByteSize.new(File.size(filename))} data file for #{team}."
          content_type 'application/zip'
          header['Content-Disposition'] = "attachment; filename=#{File.basename(filename)}"
          File.binread filename
        end
      end
    end
  end
end
