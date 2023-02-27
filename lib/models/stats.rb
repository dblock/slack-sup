class Stats
  include ActiveModel::Model
  include SlackSup::Models::Mixins::Pluralize

  attr_accessor :teams_count
  attr_accessor :teams_active_count
  attr_accessor :channels_count
  attr_accessor :channels_enabled_count
  attr_accessor :rounds_count
  attr_accessor :sups_count
  attr_accessor :users_in_sups_count
  attr_accessor :users_opted_in_count
  attr_accessor :users_count
  attr_accessor :outcomes

  def initialize
    @teams_count = Team.count
    @teams_active_count = Team.active.count
    @channels_count = Channel.count
    @channels_enabled_count = Channel.enabled.count
    @rounds_count = Round.count
    @sups_count = Sup.count
    @users_in_sups_count = Sup.distinct(:user_ids).count
    @users_opted_in_count = User.opted_in.count
    @users_count = User.count
    @outcomes = Hash[
      Sup.collection.aggregate(
        [
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
    messages << "S'Up connects #{pluralize(teams_active_count, 'team')} in #{pluralize(channels_enabled_count, 'channel')} with #{users_opted_in_count_percent}% (#{users_opted_in_count}/#{users_count}) of users opted in."
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
