# a Sup round
class Round
  include Mongoid::Document
  include Mongoid::Timestamps

  SIZE = 3
  TIMEOUT = 60

  belongs_to :team
  validates_presence_of :team
  has_many :sups, dependent: :destroy

  # generate a new sup round for a team
  def self.for(team)
    Round.create!(team: team)
  end

  after_create :run

  private

  def run
    return if @started_at
    @started_at = Time.now.utc
    logger.info "Generating sups for #{team} of #{team.users.enabled.count} users."
    remaining_users = team.users.enabled.to_a.shuffle
    begin
      solve(remaining_users)
      Ambit.fail!
    rescue Ambit::ChoicesExhausted
      @started_at = nil
      logger.info "Finished round for #{team}."
    end
  end

  def solve(remaining_users)
    combination = group(remaining_users)
    Ambit.clear! if @started_at + Round::TIMEOUT.seconds < Time.now.utc
    Ambit.fail! if met_recently?(combination)
    Ambit.fail! if meeting_already?(combination)
    Sup.create!(round: self, users: combination)
    logger.info "   Creating sup for #{combination.map(&:user_name)}, #{sups.count * Round::SIZE} out of #{team.users.count}."
    Ambit.clear! if sups.count * Round::SIZE == team.users.count
    solve(remaining_users - combination)
  end

  def group(remaining_users, combination = [])
    if combination.size == Round::SIZE
      combination
    else
      user = Ambit.choose(remaining_users)
      Ambit.fail! if combination.include?(user)
      group(remaining_users - [user], combination + [user])
    end
  end

  def meeting_already?(users)
    users.any? do |user|
      sups.where(user_ids: user.id).exists?
    end
  end

  def met_recently?(users)
    pairs = users.to_a.permutation(2)
    pairs.any? do |pair|
      pair.first.met_recently_with?(pair.second)
    end
  end
end
