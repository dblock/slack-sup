require 'spec_helper'

describe SlackSup::Commands::Data do
  let!(:team) { Fabricate(:team) }
  let!(:user) { Fabricate(:user, team:) }
  let(:app) { SlackSup::Server.new(team:) }
  let(:client) { app.send(:client) }

  before do
    allow(User).to receive(:find_create_or_update_by_slack_id!).and_return(user)
  end

  context 'data' do
    it 'requires a subscription' do
      expect(message: "#{SlackRubyBot.config.user} data", user: user.user_id).to respond_with_slack_message(team.subscribe_text)
    end

    context 'subscribed team' do
      let(:team) { Fabricate(:team, subscribed: true) }

      context 'another user' do
        context 'as non admin' do
          before do
            allow_any_instance_of(User).to receive(:team_admin?).and_return(false)
          end

          it 'requires an admin' do
            expect(message: "#{SlackRubyBot.config.user} data").to respond_with_slack_message(
              "Sorry, only #{user.team.team_admins_slack_mentions} can download data."
            )
          end
        end

        context 'as admin' do
          before do
            allow_any_instance_of(User).to receive(:team_admin?).and_return(true)
            allow_any_instance_of(Team).to receive(:short_lived_token).and_return('token')
          end

          it 'returns a link to download data' do
            allow(team.slack_client).to receive(:conversations_open).with(
              users: 'user'
            ).and_return(Hashie::Mash.new('channel' => { 'id' => 'D1' }))

            expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).with(
              as_user: true,
              channel: 'D1',
              text: 'Click here to download your team data.',
              attachments: [
                text: '',
                attachment_type: 'default',
                actions: [{
                  type: 'button',
                  text: 'Download',
                  url: "https://sup.playplay.io/api/data?team_id=#{team.id}&access_token=token"
                }]
              ]
            )

            expect(message: "#{SlackRubyBot.config.user} data").to respond_with_slack_message(
              "Hey #{user.slack_mention}, check your DMs for a link."
            )
          end
        end
      end
    end
  end
end
