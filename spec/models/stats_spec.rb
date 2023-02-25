require 'spec_helper'

describe Stats do
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
    expect(stats.to_s).to eq "S'Up connects no teams in no channels with 0% (0/0) of users opted in."
  end
end
