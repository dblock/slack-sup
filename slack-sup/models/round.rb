# a Sup round
class Round
  include Mongoid::Document
  include Mongoid::Timestamps
  include SlackSup::Models::Mixins::Export

  TIMEOUT = 60

  field :ran_at, type: DateTime
  field :asked_at, type: DateTime
  field :asked_again_at, type: DateTime
  field :reminded_at, type: DateTime

  belongs_to :team
  validates_presence_of :team
  has_many :sups, dependent: :destroy

  has_and_belongs_to_many :missed_users, class_name: 'User'
  has_and_belongs_to_many :vacation_users, class_name: 'User'

  field :total_users_count
  field :opted_in_users_count
  field :opted_out_users_count
  field :paired_users_count
  field :missed_users_count
  field :vacation_users_count

  after_create :run!

  def to_s
    "id=#{id}, #{team}"
  end

  def stats
    @stats ||= RoundStats.new(self)
  end

  def ask_again?
    return false unless asked_at
    return false if asked_again_at
    # do not ask within 48 hours since asked_at
    return false if Time.now.utc < (asked_at + 48.hours)

    true
  end

  def ask_again!
    return if asked_again_at

    update_attributes!(asked_again_at: Time.now.utc)
    sups.where(outcome: 'later').each(&:ask_again!)
  end

  def ask?
    return false if asked_at
    # do not ask within 24 hours
    return false if Time.now.utc < (ran_at + 24.hours)

    # only ask on sup_followup_day
    now_in_tz = Time.now.utc.in_time_zone(team.sup_tzone)
    return false unless now_in_tz.wday == team.sup_followup_wday

    # do not bother people before S'Up time
    return false if now_in_tz < now_in_tz.beginning_of_day + team.sup_time_of_day

    true
  end

  def ask!
    return if asked_at

    update_attributes!(asked_at: Time.now.utc)
    sups.each(&:ask!)
  end

  def remind?
    # don't remind if already tried to record outcome
    return false if asked_at || reminded_at

    # do not remind before 24 hours
    return false unless Time.now.utc > (ran_at + 24.hours)

    # do not bother people before S'Up time
    now_in_tz = Time.now.utc.in_time_zone(team.sup_tzone)
    return false if now_in_tz < now_in_tz.beginning_of_day + team.sup_time_of_day

    true
  end

  def remind!
    return if reminded_at

    update_attributes!(reminded_at: Time.now.utc)
    sups.each(&:remind!)
  end

  def paired_users
    User.find(sups.distinct(:user_ids))
  end

  def export!(root, options = {})
    super
    super(root, options.merge(name: 'sups', presenter: Api::Presenters::SupPresenter, coll: sups))
  end

  private

  def run!
    group!
    dm!
  end

  def group!
    return if ran_at

    update_attributes!(ran_at: Time.now.utc)
    logger.info "Generating sups for #{team} of #{team.users.suppable.count} users."
    all_users = team.users.suppable.to_a.shuffle
    begin
      solve(all_users)
      Ambit.fail!
    rescue Ambit::ChoicesExhausted
      solve_remaining(all_users - sups.map(&:users).flatten) if team.sup_odd?
      paired_count = sups.distinct(:user_ids).count
      update_attributes!(
        total_users_count: team.users.enabled.count,
        opted_in_users_count: team.users.opted_in.count,
        opted_out_users_count: team.users.opted_out.count,
        vacation_users_count: team.users.vacation.count,
        paired_users_count: paired_count,
        missed_users_count: all_users.count - paired_count,
        missed_users: all_users.count - paired_count > 25 ? [] : all_users - paired_users,
        vacation_users: team.users.vacation.count > 25 ? [] : team.users.vacation
      )
      logger.info "Finished round for team #{team}, users=#{total_users_count}, opted out=#{opted_out_users_count}, vacation=#{vacation_users_count}, paired=#{paired_users_count}, missed=#{missed_users_count}."
    end
  end

  def dm!
    sups.each do |sup|
      sup.sup!
    rescue StandardError => e
      logger.warn "Error DMing sup #{self} #{sup} #{e.message}."
    end
  end

  def solve(remaining_users)
    combination = group(remaining_users)
    Ambit.clear! if ran_at + Round::TIMEOUT.seconds < Time.now.utc
    Ambit.fail! if meeting_already?(combination)
    Ambit.fail! if met_recently?(combination)
    Ambit.fail! if same_team?(combination)
    Sup.create!(round: self, team:, users: combination)
    logger.info "   Creating sup for #{combination.map(&:user_name)}, #{sups.count * team.sup_size} out of #{team.users.suppable.count}."
    Ambit.clear! if sups.count * team.sup_size == team.users.suppable.count
    solve(remaining_users - combination)
  end

  def solve_remaining(remaining_users)
    if remaining_users.count == 1
      # find a sup to add this user to
      sups.each do |sup|
        next if met_recently?(sup.users + remaining_users)

        logger.info "   Adding #{remaining_users.map(&:user_name).and} to #{sup.users.map(&:user_name)}."
        sup.users.concat(remaining_users)
        sup.save!
        return
      end
      logger.info "   Failed to pair #{remaining_users.map(&:user_name).and}."
    elsif remaining_users.count > 0 &&
          remaining_users.count < team.sup_size &&
          !met_recently?(remaining_users)

      # pair remaining
      Sup.create!(round: self, team:, users: remaining_users)
    end
  end

  def group(remaining_users, combination = [])
    if combination.size == team.sup_size
      combination
    else
      user = Ambit.choose(remaining_users)
      Ambit.fail! if combination.include?(user)
      group(remaining_users - [user], combination + [user])
    end
  end

  def meeting_already?(users)
    users.any? do |user|
      sups.any? do |sup|
        sup.user_ids.include?(user.id)
      end
    end
  end

  def same_team?(users)
    pairs = users.to_a.permutation(2)
    pairs.any? do |pair|
      pair.first.custom_team_name == pair.last.custom_team_name &&
        pair.first.custom_team_name &&
        pair.last.custom_team_name
    end
  end

  def met_recently?(users)
    pairs = users.to_a.permutation(2)
    pairs.any? do |pair|
      Sup.where(
        :round_id.ne => _id,
        :user_ids.in => pair.map(&:id),
        :created_at.gt => Time.now.utc - team.sup_recency.weeks
      ).any? do |sup|
        pair.all? do |user|
          sup.user_ids.include?(user.id)
        end
      end
    end
  end
end
