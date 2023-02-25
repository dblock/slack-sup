class ChannelStats
  include ActiveModel::Model
  include SlackSup::Models::Mixins::Pluralize

  attr_accessor :rounds_count
  attr_accessor :sups_count
  attr_accessor :users_in_sups_count
  attr_accessor :users_opted_in_count
  attr_accessor :users_count
  attr_accessor :outcomes
  attr_accessor :channel

  def initialize(channel)
    @channel = channel
    @rounds_count = channel.rounds.count
    @sups_count = channel.sups.count
    @users_in_sups_count = channel.sups.distinct(:user_ids).count
    @users_opted_in_count = channel.users.opted_in.count
    @users_count = channel.users.count
    @outcomes = Hash[
      Sup.collection.aggregate(
        [
          { '$match' => { channel_id: channel.id } },
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

  def to_s
    messages = []
    messages << "Channel S'Up connects groups of #{channel.sup_size} people on #{channel.sup_day} after #{channel.sup_time_of_day_s} every #{channel.sup_every_n_weeks_s} in #{channel.slack_mention}."
    messages << if users_count > 0 && users_opted_in_count > 0
                  "Channel S'Up started #{channel.created_at.ago_in_words(highest_measure_only: true)} with #{users_opted_in_count_percent}% (#{users_opted_in_count}/#{users_count}) of users opted in."
                elsif users_count > 0
                  "Channel S'Up started #{channel.created_at.ago_in_words(highest_measure_only: true)} with none of the #{pluralize(users_count, 'user')}) opted in."
                else
                  "Channel S'Up started #{channel.created_at.ago_in_words(highest_measure_only: true)}."
                end
    if sups_count > 0
      messages << "Facilitated #{pluralize(sups_count, 'S\'Up')} " \
        "in #{pluralize(rounds_count, 'round')} " \
        "for #{pluralize(users_in_sups_count, 'user')} " \
        "with #{positive_outcomes_count * 100 / sups_count}% positive outcomes " \
        "from #{reported_outcomes_count * 100 / sups_count}% outcomes reported."
    end
    messages.join("\n")
  end

  private

  def users_opted_in_count_percent
    return 0 unless users_count && users_count > 0

    users_opted_in_count * 100 / users_count
  end
end
