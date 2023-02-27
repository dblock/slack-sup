class RoundStats
  include ActiveModel::Model
  include SlackSup::Models::Mixins::Pluralize

  attr_accessor :round
  attr_accessor :sups_count
  attr_accessor :users_in_sups_count
  attr_accessor :outcomes

  def initialize(round = nil)
    @round = round
    @sups_count = round.sups.count
    @users_in_sups_count = round.paired_users_count || round.sups.distinct(:user_ids).count
    @outcomes = Hash[
      Sup.collection.aggregate(
        [
          { '$match' => { round_id: round.id } },
          { '$group' => { _id: { outcome: '$outcome' }, count: { '$sum' => 1 } } }
        ]
      ).map do |row|
        [(row['_id']['outcome'] || 'unknown').to_sym, row['count']]
      end
    ]
  end

  def positive_outcomes_count
    ((outcomes[:all] || 0) + (outcomes[:some] || 0))
  end

  def reported_outcomes_count
    outcomes.values.sum - (outcomes[:unknown] || 0)
  end

  def status
    if round.ran_at && round.asked_at
      round.ran_at.to_time.ago_in_words(highest_measure_only: true)
    elsif round.ran_at
      'in progress'
    else
      'scheduled'
    end
  end

  def in_channel
    "in #{round.channel.slack_mention}"
  end

  def to_s(include_channel = false)
    "* #{status}#{include_channel ? ' ' + in_channel : nil}: #{pluralize(sups_count, 'S\'Up')} " + [
      "paired #{pluralize(users_in_sups_count, 'user')}",
      sups_count && sups_count > 0 && reported_outcomes_count && reported_outcomes_count > 0 ? percent_s(positive_outcomes_count, sups_count) + ' positive outcomes' : nil,
      sups_count && sups_count > 0 ? percent_s(reported_outcomes_count, sups_count) + ' outcomes reported' : nil,
      round.opted_out_users_count && round.opted_out_users_count > 0 ? pluralize(round.opted_out_users_count, 'opt out').to_s : nil,
      round.missed_users_count && round.missed_users_count > 0 ? pluralize(round.missed_users_count, 'missed user').to_s : nil
    ].compact.and + '.'
  end

  private

  def percent_s(count, total, no = 'no')
    pc = count && count > 0 ? count * 100 / total : 0
    pc > 0 ? "#{pc}%" : no
  end
end
