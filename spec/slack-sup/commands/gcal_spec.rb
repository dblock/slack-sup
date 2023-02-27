require 'spec_helper'

describe SlackSup::Commands::GCal do
  context 'dm' do
    include_context :subscribed_team

    before do
      ENV['GOOGLE_API_CLIENT_ID'] = 'client-id'
    end
    after do
      ENV.delete('GOOGLE_API_CLIENT_ID')
    end

    it 'requires a sup' do
      expect(message: '@sup gcal').to respond_with_slack_message(
        "Please `@sup cal date/time` inside a S'Up DM channel."
      )
    end
  end

  context 'team' do
    let!(:team) { Fabricate(:team) }
    it 'requires a subscription' do
      expect(message: '@sup gcal').to respond_with_slack_message(team.subscribe_text)
    end
  end

  context 'channel' do
    include_context :channel

    context 'subscribed team' do
      it 'requires a GOOGLE_API_CLIENT_ID' do
        expect(message: '@sup gcal').to respond_with_slack_message(
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
            expect(message: '@sup gcal', channel: 'invalid').to respond_with_slack_message(
              "Please `@sup cal date/time` inside a S'Up DM channel."
            )
          end
        end
        context 'inside a sup' do
          let!(:sup) { Fabricate(:sup, channel: channel, conversation_id: 'sup-channel-id') }
          let(:monday) { DateTime.parse('2017/1/2 8:00 AM EST').utc }
          it 'requires a date/time' do
            expect(message: '@sup gcal', channel: 'sup-channel-id').to respond_with_slack_message(
              'Please specify a date/time, eg. `@sup cal tomorrow 5pm`.'
            )
          end
          it 'creates a link' do
            Timecop.travel(monday).freeze do
              Chronic.time_class = channel.sup_tzone
              expect(message: '@sup gcal today 5pm', channel: 'sup-channel-id').to respond_with_slack_message(
                "Click this link to create a gcal for Monday, January 02, 2017 at 5:00 pm: https://sup.playplay.io/gcal?sup_id=#{sup.id}&dt=1483394400&access_token=#{team.short_lived_token}"
              )
            end
          end
        end
      end
    end
  end
end
