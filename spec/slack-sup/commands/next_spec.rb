require 'spec_helper'

describe SlackSup::Commands::Next do
  let(:tz) { 'Eastern Time (US & Canada)' }
  let(:t_in_time_zone) { Time.now.utc.in_time_zone(tz) }
  let(:wday) { t_in_time_zone.wday }
  let(:beginning_of_day) { t_in_time_zone.beginning_of_day }
  let(:team) { Fabricate(:team, subscribed: true) }
  let(:channel) { Fabricate(:channel, team: team, sup_wday: wday, sup_time_of_day: 7 * 60 * 60 + 1, sup_tz: tz) }
  let(:monday) { DateTime.parse('2017/1/2 3:00 PM EST').utc }
  let(:app) { SlackSup::Server.new(team: team) }
  let(:client) { app.send(:client) }
  before do
    Timecop.travel(monday)
    allow(team).to receive(:find_create_or_update_channel_by_channel_id!).and_return(channel)
  end
  it 'no sup' do
    expect(message: "#{SlackRubyBot.config.user} next").to respond_with_slack_message(
      'Next round is overdue Monday, January 2, 2017 at 7:00 AM EST (7 hours ago).'
    )
  end
  context 'supped' do
    before do
      allow(team).to receive(:sync!)
      channel.sup!
    end
    it 'in a week' do
      expect(message: "#{SlackRubyBot.config.user} next").to respond_with_slack_message(
        'Next round is Monday, January 9, 2017 at 7:00 AM EST (in 6 days).'
      )
    end
    context 'fast forward' do
      before do
        Timecop.travel(Time.now + 1.day)
      end
      it 'in six days' do
        expect(message: "#{SlackRubyBot.config.user} next").to respond_with_slack_message(
          'Next round is Monday, January 9, 2017 at 7:00 AM EST (in 5 days).'
        )
      end
    end
  end
end
