module Api
  module Endpoints
    class TeamsEndpoint < Grape::API
      format :json
      helpers Api::Helpers::CursorHelpers
      helpers Api::Helpers::SortHelpers
      helpers Api::Helpers::PaginationParameters
      helpers Api::Helpers::AuthHelpers

      namespace :teams do
        desc 'Get a team.'
        params do
          requires :id, type: String, desc: 'Team ID.'
        end
        get ':id' do
          team = Team.find(_id: params[:id]) || error!('Not Found', 404)
          authorize_team! team
          present team, with: Api::Presenters::TeamPresenter
        end

        desc 'Get all the teams.'
        params do
          optional :active, type: Grape::API::Boolean, desc: 'Return active teams only.'
          use :pagination
        end
        sort Team::SORT_ORDERS
        get do
          teams = headers['X-Access-Token'] ?
            Team.where(api_token: headers['X-Access-Token']) :
            Team.where(api: true, api_token: nil)
          teams = teams.active if params[:active]
          teams = paginate_and_sort_by_cursor(teams, default_sort_order: '-_id')
          present teams, with: Api::Presenters::TeamsPresenter
        end

        desc 'Create a team using an OAuth token.'
        params do
          requires :code, type: String
          optional :state, type: String
        end
        post do
          client = Slack::Web::Client.new

          raise 'Missing SLACK_CLIENT_ID or SLACK_CLIENT_SECRET.' unless ENV.key?('SLACK_CLIENT_ID') && ENV.key?('SLACK_CLIENT_SECRET')

          options = {
            client_id: ENV['SLACK_CLIENT_ID'],
            client_secret: ENV['SLACK_CLIENT_SECRET'],
            code: params[:code]
          }

          rc = client.send(SlackRubyBotServer.config.oauth_access_method, options)

          token = nil
          access_token = nil
          user_id = nil
          bot_user_id = nil
          team_id = nil
          team_name = nil
          oauth_scope = nil
          oauth_version = SlackRubyBotServer::Config.oauth_version

          case oauth_version
          when :v2
            access_token = rc['access_token']
            token = rc['access_token']
            user_id = rc['authed_user']['id']
            bot_user_id = rc['bot_user_id']
            team_id = rc['team']['id']
            team_name = rc['team']['name']
            oauth_scope = rc['scope']
          when :v1
            raise 'invalid OAuth version'
          end

          team = Team.where(token: token).first
          team ||= Team.where(team_id: team_id, oauth_version: oauth_version).first
          team ||= Team.where(team_id: team_id).first

          if team
            team.ping_if_active!

            team.update_attributes!(
              oauth_version: oauth_version,
              oauth_scope: oauth_scope,
              activated_user_id: user_id,
              activated_user_access_token: access_token,
              bot_user_id: bot_user_id
            )

            raise "Team #{team.name} is already registered." if team.active?

            team.activate!(token)
          else
            team = Team.create!(
              token: token,
              oauth_version: oauth_version,
              oauth_scope: oauth_scope,
              team_id: team_id,
              name: team_name,
              activated_user_id: user_id,
              activated_user_access_token: access_token,
              bot_user_id: bot_user_id
            )
          end

          team.inform! Team::INSTALLED_TEXT

          options = params.slice(:state)

          SlackRubyBotServer::Service.instance.create!(team, options)
          present team, with: Presenters::TeamPresenter
        end
      end
    end
  end
end
