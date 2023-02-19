require 'spec_helper'

describe SlackSup::Commands::Rounds do
  let(:team) { Fabricate(:team, subscribed: true) }
  let(:channel) { Fabricate(:channel, team: team, channel_id: 'channel') }
  let(:app) { SlackSup::Server.new(team: team) }
  let(:client) { app.send(:client) }
  it 'empty stats' do
    expect(message: "#{SlackRubyBot.config.user} rounds").to respond_with_slack_message(
      "Team S'Up facilitated 0 rounds."
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
        Sup.asc(:_id).first.update_attributes!(outcome: 'all')
        Timecop.travel(Time.now + 1.year)
        channel.sup!
      end
    end
    it 'reports counts' do
      Timecop.travel(Time.now + 731.days)
      expect(message: "#{SlackRubyBot.config.user} rounds 2").to respond_with_slack_message(
        "Team S'Up facilitated 2 rounds.\n" \
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
      expect(message: "#{SlackRubyBot.config.user} rounds 2").to respond_with_slack_message(
        "Team S'Up facilitated 1 round.\n" \
        "* in progress: 1 S'Up paired 3 users, no outcomes reported, 1 opt out and 2 missed users."
      )
    end
  end
end
