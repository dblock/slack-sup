class TeamStats
  include ActiveModel::Model
  include SlackSup::Models::Mixins::Pluralize

  attr_accessor :channels_count
  attr_accessor :channels_enabled_count
  attr_accessor :rounds_count
  attr_accessor :sups_count
  attr_accessor :users_in_sups_count
  attr_accessor :users_opted_in_count
  attr_accessor :users_count
  attr_accessor :outcomes
  attr_accessor :team

  def initialize(team)
    @team = team
    @channels_count = team.channels.count
    @channels_enabled_count = team.channels.enabled.count
    channel_ids = team.channels.enabled.distinct(:_id)
    @rounds_count = Round.where(:channel_id.in => channel_ids).count
    @sups_count = Sup.where(:channel_id.in => channel_ids).count
    @users_in_sups_count = User.where(:_id.in => Sup.where(:channel_id.in => channel_ids).distinct(:user_ids)).distinct(:user_id).count
    @users_opted_in_count = User.where(:channel_id.in => channel_ids, opted_in: true).distinct(:user_id).count
    @users_count = User.where(:channel_id.in => channel_ids).distinct(:user_id).count
    @outcomes = Hash[
      Sup.collection.aggregate(
        [
          { '$match' => { channel_id: { '$in' => channel_ids } } },
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
    messages << "Team S'Up connects #{pluralize(users_opted_in_count, 'user')} in #{pluralize(channels_count, 'channel')}."
    if users_count > 0 && users_opted_in_count > 0
      messages << "Team S'Up has #{users_opted_in_count_percent}% (#{users_opted_in_count}/#{users_count}) of users opted in."
    elsif users_count > 0
      messages << "Team S'Up has none of the #{pluralize(users_count, 'user')}) opted in."
    end
    if sups_count > 0
      messages << "Facilitated #{pluralize(sups_count, 'S\'Up')} " \
        "in #{pluralize(rounds_count, 'round')} " \
        "for #{pluralize(users_count, 'user')} " \
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
