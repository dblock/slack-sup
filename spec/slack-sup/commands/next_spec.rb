require 'spec_helper'

describe SlackSup::Commands::Next do
  include_context :subscribed_team

  let(:tz) { 'Eastern Time (US & Canada)' }
  let(:t_in_time_zone) { Time.now.utc.in_time_zone(tz) }
  let(:wday) { t_in_time_zone.wday }
  let(:beginning_of_day) { t_in_time_zone.beginning_of_day }
  let(:monday) { DateTime.parse('2017/1/2 3:00 PM EST').utc }

  before do
    Timecop.travel(monday)
  end

  context 'dm' do
    let!(:channel1) { Fabricate(:channel, team: team, sup_wday: wday, sup_time_of_day: 7 * 60 * 60 + 1, sup_tz: tz) }
    let!(:channel2) { Fabricate(:channel, team: team, sup_wday: wday, sup_time_of_day: 9 * 60 * 60 + 1, sup_tz: tz) }
    it 'returns all the next rounds' do
      expect(message: "#{SlackRubyBot.config.user} next", channel: 'DM').to respond_with_slack_message([
        "Next round in #{channel1.slack_mention} is overdue Monday, January 2, 2017 at 7:00 AM EST (7 hours ago).",
        "Next round in #{channel2.slack_mention} is overdue Monday, January 2, 2017 at 9:00 AM EST (5 hours ago)."
      ].join("\n"))
    end
    context 'supped' do
      before do
        allow(channel1).to receive(:sync!)
        channel1.sup!
      end
      it 'in a week' do
        expect(message: "#{SlackRubyBot.config.user} next", channel: 'DM').to respond_with_slack_message([
          "Next round in #{channel1.slack_mention} is Monday, January 9, 2017 at 7:00 AM EST (in 6 days).",
          "Next round in #{channel2.slack_mention} is overdue Monday, January 2, 2017 at 9:00 AM EST (5 hours ago)."
        ].join("\n"))
      end
    end
  end

  context 'channel' do
    let(:channel) { Fabricate(:channel, channel_id: 'channel', team: team, sup_wday: wday, sup_time_of_day: 7 * 60 * 60 + 1, sup_tz: tz) }
    it 'no sup' do
      expect(message: "#{SlackRubyBot.config.user} next").to respond_with_slack_message(
        "Next round in #{channel.slack_mention} is overdue Monday, January 2, 2017 at 7:00 AM EST (7 hours ago)."
      )
    end
    context 'supped' do
      before do
        allow(channel).to receive(:sync!)
        channel.sup!
      end
      it 'in a week' do
        expect(message: "#{SlackRubyBot.config.user} next").to respond_with_slack_message(
          "Next round in #{channel.slack_mention} is Monday, January 9, 2017 at 7:00 AM EST (in 6 days)."
        )
      end
      context 'fast forward' do
        before do
          Timecop.travel(Time.now + 1.day)
        end
        it 'in six days' do
          expect(message: "#{SlackRubyBot.config.user} next").to respond_with_slack_message(
            "Next round in #{channel.slack_mention} is Monday, January 9, 2017 at 7:00 AM EST (in 5 days)."
          )
        end
      end
    end
  end
end
