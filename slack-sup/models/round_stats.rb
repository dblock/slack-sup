class RoundStats
  include ActiveModel::Model

  attr_accessor :round, :sups_count, :users_in_sups_count, :outcomes

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
end
