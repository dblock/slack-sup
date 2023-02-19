class Stats
  include ActiveModel::Model

  attr_accessor :rounds_count
  attr_accessor :sups_count
  attr_accessor :users_in_sups_count
  attr_accessor :users_opted_in_count
  attr_accessor :users_count
  attr_accessor :outcomes
  attr_accessor :channel

  def initialize(channel = nil)
    @channel = channel
    channel ? initialize_with_channel : initialize_without_channel
  end

  def positive_outcomes_count
    ((outcomes[:all] || 0) + (outcomes[:some] || 0))
  end

  def reported_outcomes_count
    outcomes.values.sum - (outcomes[:unknown] || 0)
  end

  private

  def initialize_with_channel
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

  def initialize_without_channel
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
end
