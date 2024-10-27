require 'spec_helper'

describe SlackSup::Commands::GCal do
  let!(:team) { Fabricate(:team) }
  let!(:user) { Fabricate(:user, team:) }
  let(:app) { SlackSup::Server.new(team:) }
  let(:client) { app.send(:client) }

  before do
    allow(User).to receive(:find_create_or_update_by_slack_id!).and_return(user)
  end

  context 'gcal' do
    it 'requires a subscription' do
      expect(message: "#{SlackRubyBot.config.user} gcal", user: user.user_id).to respond_with_slack_message(team.subscribe_text)
    end

    context 'subscribed team' do
      let(:team) { Fabricate(:team, subscribed: true) }

      it 'requires a GOOGLE_API_CLIENT_ID' do
        expect(message: "#{SlackRubyBot.config.user} gcal", user: user.user_id).to respond_with_slack_message(
          'Missing GOOGLE_API_CLIENT_ID.'
        )
      end

      context 'with GOOGLE_API_CLIENT_ID' do
        before do
          ENV['GOOGLE_API_CLIENT_ID'] = 'client-id'
        end

        after do
          ENV.delete('GOOGLE_API_CLIENT_ID')
        end

        context 'outside of a sup' do
          it 'requires a sup DM' do
            expect(message: "#{SlackRubyBot.config.user} gcal", user: user.user_id).to respond_with_slack_message(
              "Please `@sup gcal date/time` inside a S'Up DM channel."
            )
          end
        end

        context 'inside a sup' do
          let!(:sup) { Fabricate(:sup, team:, channel_id: 'sup-channel-id') }
          let(:monday) { DateTime.parse('2017/1/2 8:00 AM EST').utc }

          it 'requires a date/time' do
            expect(message: "#{SlackRubyBot.config.user} gcal", user: user.user_id, channel: 'sup-channel-id').to respond_with_slack_message(
              'Please specify a date/time, eg. `@sup gcal tomorrow 5pm`.'
            )
          end

          context 'monday' do
            let(:message_command) { SlackRubyBot::Hooks::Message.new }

            before do
              allow_any_instance_of(Team).to receive(:short_lived_token).and_return('token')
              Timecop.travel(monday).freeze
            end

            it 'creates a link' do
              expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).with(
                {
                  as_user: true,
                  channel: 'sup-channel-id',
                  text: 'Click the button below to create a gcal for Monday, January 02, 2017 at 5:00 pm.',
                  attachments: [
                    {
                      text: '',
                      attachment_type: 'default',
                      actions: [{
                        type: 'button',
                        text: 'Add to Calendar',
                        url: "https://sup.playplay.io/gcal?sup_id=#{sup.id}&dt=1483394400&access_token=token"
                      }]
                    }
                  ]
                }
              )

              message_command.call(
                client,
                Hashie::Mash.new(
                  text: "#{SlackRubyBot.config.user} gcal today 5pm",
                  channel: 'sup-channel-id', user: user.user_id
                )
              )
            end
          end
        end
      end
    end
  end
end
