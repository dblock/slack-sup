class Stats
  include ActiveModel::Model

  attr_accessor :rounds_count, :sups_count, :users_in_sups_count, :users_opted_in_count, :users_count, :outcomes, :team

  def initialize(team = nil)
    @team = team
    team ? initialize_with_team : initialize_without_team
  end

  def positive_outcomes_count
    ((outcomes[:all] || 0) + (outcomes[:some] || 0))
  end

  def reported_outcomes_count
    outcomes.values.sum - (outcomes[:unknown] || 0)
  end

  private

  def initialize_with_team
    @rounds_count = team.rounds.count
    @sups_count = team.sups.count
    @users_in_sups_count = team.sups.distinct(:user_ids).count
    @users_opted_in_count = team.users.opted_in.count
    @users_count = team.users.count
    @outcomes = Hash[
      Sup.collection.aggregate(
        [
          { '$match' => { team_id: team.id } },
          { '$group' => { _id: { outcome: '$outcome' }, count: { '$sum' => 1 } } }
        ]
      ).map do |row|
        [(row['_id']['outcome'] || 'unknown').to_sym, row['count']]
      end
    ]
  end

  def initialize_without_team
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
