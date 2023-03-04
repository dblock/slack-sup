require 'spec_helper'

describe SlackSup::Commands::Rounds do
  context 'team' do
    include_context :team

    it 'requires a subscription' do
      expect(message: '@sup rounds').to respond_with_slack_message(team.subscribe_text)
    end
  end

  context 'dm' do
    include_context :subscribed_team

    it 'empty stats' do
      expect(message: '@sup rounds', channel: 'DM').to respond_with_slack_message(
        "Team S'Up facilitated 0 rounds in 0 channels."
      )
    end
    context 'with outcomes' do
      let!(:channel1) { Fabricate(:channel, team: team) }
      let!(:channel1_user1) { Fabricate(:user, channel: channel1) }
      let!(:channel1_user2) { Fabricate(:user, channel: channel1) }
      let!(:channel1_user3) { Fabricate(:user, channel: channel1) }
      let!(:channel2) { Fabricate(:channel, team: team) }
      let!(:channel2_user1) { Fabricate(:user, channel: channel2) }
      let!(:channel2_user2) { Fabricate(:user, channel: channel2) }
      let!(:channel2_user3) { Fabricate(:user, channel: channel2) }
      before do
        allow_any_instance_of(Channel).to receive(:sync!)
        allow_any_instance_of(Sup).to receive(:dm!)
        Timecop.freeze do
          round1 = channel1.sup!
          round1.ask!
          round1.sups.desc(:_id).first.update_attributes!(outcome: 'all')
          round2 = channel2.sup!
          round2.ask!
          Timecop.travel(Time.now + 1.year)
          channel1.sup!
          channel2.sup!
        end
      end
      it 'reports counts' do
        Timecop.travel(Time.now + 731.days)
        expect(message: '@sup rounds 4', channel: 'DM').to respond_with_slack_message([
          "Team S'Up facilitated 4 rounds in 2 channels.",
          "* in progress in #{channel2.slack_mention}: 1 S'Up paired 3 users and no outcomes reported.",
          "* in progress in #{channel1.slack_mention}: 1 S'Up paired 3 users and no outcomes reported.",
          "* 2 years ago in #{channel2.slack_mention}: 1 S'Up paired 3 users and no outcomes reported.",
          "* 2 years ago in #{channel1.slack_mention}: 1 S'Up paired 3 users, 100% positive outcomes and 100% outcomes reported."
        ].join("\n"))
      end
    end
  end

  context 'channel' do
    include_context :channel

    before do
      allow_any_instance_of(Slack::Web::Client).to receive(:conversations_info)
    end

    it 'empty stats' do
      expect(message: '@sup rounds').to respond_with_slack_message(
        "Channel S'Up facilitated 0 rounds."
      )
    end
    context 'with outcomes' do
      let!(:user1) { Fabricate(:user, channel: channel) }
      let!(:user2) { Fabricate(:user, channel: channel) }
      let!(:user3) { Fabricate(:user, channel: channel) }
      before do
        allow(channel).to receive(:sync!)
        allow_any_instance_of(Sup).to receive(:dm!)
        Timecop.freeze do
          round = channel.sup!
          round.ask!
          Sup.desc(:_id).first.update_attributes!(outcome: 'all')
          Timecop.travel(Time.now + 1.year)
          channel.sup!
        end
      end
      it 'reports counts' do
        Timecop.travel(Time.now + 731.days)
        expect(message: '@sup rounds 2').to respond_with_slack_message(
          "Channel S'Up facilitated 2 rounds.\n" \
          "* in progress: 1 S'Up paired 3 users and no outcomes reported.\n" \
          "* 2 years ago: 1 S'Up paired 3 users, 100% positive outcomes and 100% outcomes reported."
        )
      end
    end
    context 'with opt outs and misses' do
      let!(:user1) { Fabricate(:user, channel: channel) }
      let!(:user2) { Fabricate(:user, channel: channel) }
      let!(:user3) { Fabricate(:user, channel: channel) }
      let!(:user4) { Fabricate(:user, channel: channel, opted_in: false) }
      let!(:user5) { Fabricate(:user, channel: channel, enabled: false) }
      let!(:user6) { Fabricate(:user, channel: channel) }
      let!(:user7) { Fabricate(:user, channel: channel) }
      before do
        channel.update_attributes!(sup_odd: false)
        allow(channel).to receive(:sync!)
        allow_any_instance_of(Sup).to receive(:dm!)
        channel.sup!
      end
      it 'reports counts' do
        expect(message: '@sup rounds 2').to respond_with_slack_message(
          "Channel S'Up facilitated 1 round.\n" \
          "* in progress: 1 S'Up paired 3 users, no outcomes reported, 1 opt out and 2 missed users."
        )
      end
    end
  end
end
