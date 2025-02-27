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
          team = Team.where(_id: params[:id], api: true).first || error!('Not Found', 404)
          authorize! team
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
        end
        post do
          client = Slack::Web::Client.new

          raise 'Missing SLACK_CLIENT_ID or SLACK_CLIENT_SECRET.' unless ENV.key?('SLACK_CLIENT_ID') && ENV.key?('SLACK_CLIENT_SECRET')

          rc = client.oauth_access(
            client_id: ENV.fetch('SLACK_CLIENT_ID', nil),
            client_secret: ENV.fetch('SLACK_CLIENT_SECRET', nil),
            code: params[:code]
          )

          token = rc['bot']['bot_access_token']
          bot_user_id = rc['bot']['bot_user_id']
          user_id = rc['user_id']
          access_token = rc['access_token']
          team = Team.where(token:).first
          team ||= Team.where(team_id: rc['team_id']).first

          if team
            team.update_attributes!(
              token:,
              activated_user_id: user_id,
              activated_user_access_token: access_token,
              bot_user_id:
            )

            raise "Team #{team.name} is already registered." if team.active?

            team.activate!(token)
          else
            team = Team.create!(
              token:,
              team_id: rc['team_id'],
              name: rc['team_name'],
              activated_user_id: user_id,
              activated_user_access_token: access_token,
              bot_user_id:
            )
          end

          team.inform! Team::INSTALLED_TEXT

          SlackRubyBotServer::Service.instance.create!(team)
          present team, with: Api::Presenters::TeamPresenter
        end
      end
    end
  end
end
