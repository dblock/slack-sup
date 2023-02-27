require 'spec_helper'

describe Api::Endpoints::TeamsEndpoint do
  include Api::Test::EndpointTest

  context 'teams' do
    subject do
      client.teams
    end
    it 'lists no teams' do
      expect(subject.to_a.size).to eq 0
    end
    context 'with teams' do
      let!(:team1) { Fabricate(:team, api: false) }
      let!(:team2) { Fabricate(:team, api: true) }
      it 'lists teams with api enabled' do
        expect(subject.to_a.size).to eq 1
        expect(subject.first.id).to eq team2.id.to_s
      end
    end
  end

  context 'team' do
    it 'requires code' do
      expect { client.teams._post }.to raise_error Faraday::ClientError do |e|
        json = JSON.parse(e.response[:body])
        expect(json['message']).to eq 'Invalid parameters.'
        expect(json['type']).to eq 'param_error'
      end
    end

    context 'cursor' do
      it_behaves_like 'a cursor api', Team
    end

    context 'a team with api false' do
      let!(:team) { Fabricate(:team, api: false) }
      it 'is not returned' do
        expect(client.teams.count).to eq 0
      end
    end

    context 'a team with api and token' do
      let!(:team) { Fabricate(:team, api: true, api_token: 'token') }
      it 'is not returned' do
        expect(client.teams.count).to eq 0
      end
      it 'is returned with api token header' do
        Fabricate(:team, api: true) # another team
        Fabricate(:team, api: false) # another team
        client.headers.update('X-Access-Token' => 'token')
        expect(client.teams.count).to eq 1
        expect(client.teams.first.id).to eq team.id.to_s
      end
      it 'is not returned directly without a token' do
        expect { client.team(id: team.id).resource }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['error']).to eq 'Access Denied'
        end
      end
      it 'is returned directly' do
        client.headers.update('X-Access-Token' => team.api_token)
        returned_team = client.team(id: team.id)
        expect(returned_team.id).to eq team.id.to_s
      end
    end

    context 'a team with api true' do
      let!(:existing_team) { Fabricate(:team, api: true) }
      it 'is returned in the collection' do
        expect(client.teams.count).to eq 1
      end
      it 'is returned directly' do
        team = client.team(id: existing_team.id)
        expect(team.id).to eq existing_team.id.to_s
        expect(team._links.self._url).to eq "http://example.org/api/teams/#{existing_team.id}"
      end
    end

    context 'register' do
      before do
        oauth_access = {
          'access_token' => 'token',
          'token_type' => 'bot',
          'bot_user_id' => 'bot_user_id',
          'team' => {
            'id' => 'team_id',
            'name' => 'team_name'
          },
          'authed_user' => {
            'id' => 'activated_user_id',
            'access_token' => 'user_token',
            'token_type' => 'user'
          }
        }
        ENV['SLACK_CLIENT_ID'] = 'client_id'
        ENV['SLACK_CLIENT_SECRET'] = 'client_secret'
        allow_any_instance_of(Slack::Web::Client).to receive(:conversations_open).with(
          users: 'activated_user_id'
        ).and_return(
          'channel' => {
            'id' => 'C1'
          }
        )
        allow_any_instance_of(Slack::Web::Client).to receive(:oauth_v2_access).with(
          hash_including(
            code: 'code',
            client_id: 'client_id',
            client_secret: 'client_secret'
          )
        ).and_return(oauth_access)
      end
      after do
        ENV.delete('SLACK_CLIENT_ID')
        ENV.delete('SLACK_CLIENT_SECRET')
      end
      it 'creates a team' do
        expect_any_instance_of(Team).to receive(:inform!).with(Team::INSTALLED_TEXT)
        expect(SlackRubyBotServer::Service.instance).to receive(:start!)
        expect do
          team = client.teams._post(code: 'code')
          expect(team.team_id).to eq 'team_id'
          expect(team.name).to eq 'team_name'
          team = Team.find(team.id)
          expect(team.token).to eq 'token'
          expect(team.bot_user_id).to eq 'bot_user_id'
          expect(team.activated_user_id).to eq 'activated_user_id'
        end.to change(Team, :count).by(1)
      end
      it 'reactivates a deactivated team' do
        expect_any_instance_of(Team).to receive(:inform!).with(Team::INSTALLED_TEXT)
        expect(SlackRubyBotServer::Service.instance).to receive(:start!)
        existing_team = Fabricate(:team, token: 'token', active: false)
        expect do
          team = client.teams._post(code: 'code')
          expect(team.team_id).to eq existing_team.team_id
          expect(team.name).to eq existing_team.name
          expect(team.active).to be true
          team = Team.find(team.id)
          expect(team.token).to eq 'token'
          expect(team.active).to be true
          expect(team.bot_user_id).to eq 'bot_user_id'
          expect(team.activated_user_id).to eq 'activated_user_id'
        end.to_not change(Team, :count)
      end
      it 'returns a useful error when team already exists' do
        existing_team = Fabricate(:team, token: 'token')
        allow_any_instance_of(Team).to receive(:ping_if_active!)
        expect { client.teams._post(code: 'code') }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['message']).to eq "Team #{existing_team.name} is already registered."
        end
      end
      it 'reactivates a deactivated team with a different code' do
        expect_any_instance_of(Team).to receive(:inform!).with(Team::INSTALLED_TEXT)
        expect(SlackRubyBotServer::Service.instance).to receive(:start!)
        existing_team = Fabricate(:team, api: true, token: 'old', team_id: 'team_id', active: false)
        expect do
          team = client.teams._post(code: 'code')
          expect(team.team_id).to eq existing_team.team_id
          expect(team.name).to eq existing_team.name
          expect(team.active).to be true
          team = Team.find(team.id)
          expect(team.token).to eq 'token'
          expect(team.active).to be true
          expect(team.bot_user_id).to eq 'bot_user_id'
          expect(team.activated_user_id).to eq 'activated_user_id'
        end.to_not change(Team, :count)
      end
      context 'with mailchimp settings' do
        before do
          SlackRubyBotServer::Mailchimp.configure do |config|
            config.mailchimp_api_key = 'api-key'
            config.mailchimp_list_id = 'list-id'
          end
        end
        after do
          SlackRubyBotServer::Mailchimp.config.reset!
        end

        let(:list) { double(Mailchimp::List, members: double(Mailchimp::List::Members)) }

        it 'subscribes to the mailing list' do
          expect_any_instance_of(Team).to receive(:inform!).with(Team::INSTALLED_TEXT)
          expect(SlackRubyBotServer::Service.instance).to receive(:start!)

          allow_any_instance_of(Slack::Web::Client).to receive(:users_info).with(
            user: 'activated_user_id'
          ).and_return(
            user: {
              profile: {
                email: 'user@example.com',
                first_name: 'First',
                last_name: 'Last'
              }
            }
          )

          allow_any_instance_of(Mailchimp::Client).to receive(:lists).with('list-id').and_return(list)

          expect(list.members).to receive(:where).with(email_address: 'user@example.com').and_return([])

          expect(list.members).to receive(:create_or_update).with(
            email_address: 'user@example.com',
            merge_fields: {
              'FNAME' => 'First',
              'LNAME' => 'Last',
              'BOT' => 'Sup'
            },
            status: 'pending',
            name: nil,
            tags: %w[sup trial],
            unique_email_id: 'team_id-activated_user_id'
          )

          client.teams._post(code: 'code')
        end
        after do
          ENV.delete('MAILCHIMP_API_KEY')
          ENV.delete('MAILCHIMP_LIST_ID')
        end
      end
    end
  end
end
