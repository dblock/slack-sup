require 'spec_helper'

describe Stats do
  context 'global' do
    let(:stats) { Stats.new }
    it 'reports counts' do
      expect(stats.rounds_count).to eq 0
      expect(stats.sups_count).to eq 0
      expect(stats.users_in_sups_count).to eq 0
      expect(stats.users_opted_in_count).to eq 0
      expect(stats.users_count).to eq 0
      expect(stats.positive_outcomes_count).to eq 0
      expect(stats.reported_outcomes_count).to eq 0
      expect(stats.outcomes).to eq({})
      expect(stats.channel).to be nil
    end
  end
  context 'channel' do
    let(:channel) { Fabricate(:channel) }
    let(:stats) { Stats.new(channel) }
    it 'reports counts' do
      expect(stats.rounds_count).to eq 0
      expect(stats.sups_count).to eq 0
      expect(stats.users_in_sups_count).to eq 0
      expect(stats.users_opted_in_count).to eq 0
      expect(stats.positive_outcomes_count).to eq 0
      expect(stats.reported_outcomes_count).to eq 0
      expect(stats.users_count).to eq 0
      expect(stats.outcomes).to eq({})
      expect(stats.channel).to eq channel
    end
    context 'with outcomes' do
      let!(:user1) { Fabricate(:user, channel: channel) }
      let!(:user2) { Fabricate(:user, channel: channel) }
      let!(:user3) { Fabricate(:user, channel: channel) }
      before do
        allow(channel).to receive(:sync!)
        allow_any_instance_of(Sup).to receive(:dm!)
        2.times do
          channel.sup!
          Timecop.travel(Time.now + 1.year)
        end
        Sup.first.update_attributes!(outcome: 'all')
      end
      it 'reports counts' do
        expect(stats.rounds_count).to eq 2
        expect(stats.sups_count).to eq 2
        expect(stats.users_in_sups_count).to eq 3
        expect(stats.users_opted_in_count).to eq 3
        expect(stats.users_count).to eq 3
        expect(stats.positive_outcomes_count).to eq 1
        expect(stats.reported_outcomes_count).to eq 1
        expect(stats.outcomes).to eq(all: 1, unknown: 1)
        expect(stats.channel).to eq channel
      end
    end
  end
end
