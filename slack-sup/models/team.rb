class Team
  # non-bot access token
  field :access_token, type: String

  # enable API for this team
  field :api, type: Boolean, default: false

  # sup size
  field :sup_size, type: Integer, default: 3
  # sup frequency in weeks
  field :sup_time_of_day, type: Integer, default: 9 * 60 * 60
  field :sup_every_n_weeks, type: Integer, default: 1
  # sup day of the week, defaults to Monday
  field :sup_wday, type: Integer, default: 1
  field :sup_tz, type: String, default: 'Eastern Time (US & Canada)'
  validates_presence_of :sup_tz

  # custom team field
  field :team_field_label, type: String
  field :team_field_label_id, type: String

  field :stripe_customer_id, type: String
  field :subscribed, type: Boolean, default: false
  field :subscribed_at, type: DateTime

  scope :api, -> { where(api: true) }

  has_many :users, dependent: :destroy
  has_many :rounds, dependent: :destroy
  has_many :sups, dependent: :destroy

  after_update :inform_subscribed_changed!
  before_validation :validate_team_field_label
  before_validation :validate_team_field_label_id
  before_validation :validate_sup_time_of_day
  before_validation :validate_every_n_weeks
  before_validation :validate_sup_size

  def api_url
    return unless api?
    "#{SlackSup::Service.api_url}/teams/#{id}"
  end

  def asleep?(dt = 3.weeks)
    return false unless subscription_expired?
    time_limit = Time.now.utc - dt
    created_at <= time_limit
  end

  def sup!
    sync!
    rounds.create!
  end

  def ask!
    sup = last_sup
    return unless sup && sup.ask?
    sup.ask!
    sup
  end

  def last_sup
    rounds.desc(:created_at).first
  end

  def last_sup_at
    sup = last_sup
    sup ? sup.created_at : nil
  end

  def sup_time_of_day_s
    Time.at(sup_time_of_day).utc.strftime('%l:%M %p').strip
  end

  def sup_every_n_weeks_s
    sup_every_n_weeks == 1 ? 'week' : "#{sup_every_n_weeks} weeks"
  end

  def sup_day
    Date::DAYNAMES[sup_wday]
  end

  def sup_tzone
    ActiveSupport::TimeZone.new(sup_tz)
  end

  # is it time to sup?
  def sup?
    # only sup on a certain day of the week
    now_in_tz = Time.now.utc.in_time_zone(sup_tzone)
    return false unless now_in_tz.wday == sup_wday
    # sup after 9am by default
    return false if now_in_tz < now_in_tz.beginning_of_day + sup_time_of_day
    # don't sup more than once a week
    time_limit = Time.now.utc - sup_every_n_weeks.weeks
    (last_sup_at || time_limit) <= time_limit
  end

  def inform!(message)
    client = Slack::Web::Client.new(token: token)
    members = client.paginate(:users_list, presence: false).map(&:members).flatten
    members.select(&:is_admin).each do |admin|
      channel = client.im_open(user: admin.id)
      logger.info "Sending DM '#{message}' to #{admin.name}."
      client.chat_postMessage(text: message, channel: channel.channel.id, as_user: true)
    end
  end

  def subscription_expired?
    return false if subscribed?
    (created_at + 2.weeks) < Time.now
  end

  def subscribe_text
    [trial_expired_text, subscribe_team_text].compact.join(' ')
  end

  def update_cc_text
    "Update your credit card info at #{SlackSup::Service.url}/update_cc?team_id=#{team_id}."
  end

  # synchronize users with slack
  def sync!
    client = Slack::Web::Client.new(token: token)
    members = client.paginate(:users_list, presence: false).map(&:members).flatten
    humans = members.select do |member|
      !member.is_bot &&
        !member.deleted &&
        !member.is_restricted &&
        !member.is_ultra_restricted &&
        member.id != 'USLACKBOT'
    end.map do |member|
      existing_user = User.where(user_id: member.id).first
      existing_user ||= User.new(user_id: member.id, team: self)
      existing_user.user_name = member.name
      existing_user.real_name = member.real_name
      begin
        existing_user.update_custom_profile
      rescue StandardError => e
        logger.warn "Error updating custom profile for #{existing_user}: #{e.message}."
      end
      existing_user
    end
    humans.each do |human|
      state = if human.persisted?
                human.enabled? ? 'active' : 'back'
              else
                'new'
      end
      logger.info "Team #{self}: #{human} is #{state}."
      human.enabled = true
      human.save!
    end
    (users - humans).each do |dead_user|
      next unless dead_user.enabled?
      logger.info "Team #{self}: #{dead_user} was disabled."
      dead_user.enabled = false
      dead_user.save!
    end
  end

  private

  def validate_team_field_label
    return unless team_field_label && team_field_label_changed?
    client = Slack::Web::Client.new(token: access_token)
    profile_fields = client.team_profile_get.profile.fields
    label = profile_fields.detect { |field| field.label.casecmp(team_field_label.downcase).zero? }
    if label
      self.team_field_label_id = label.id
      self.team_field_label = label.label
    else
      errors.add(:team_field_label, "Custom profile team field _#{team_field_label}_ is invalid. Possible values are _#{profile_fields.map(&:label).join('_, _')}_.")
    end
  end

  def validate_team_field_label_id
    self.team_field_label_id = nil unless team_field_label
  end

  def validate_sup_time_of_day
    return if sup_time_of_day && sup_time_of_day > 0 && sup_time_of_day < 24 * 60 * 60
    errors.add(:sup_time_of_day, "Sup time of day _#{sup_time_of_day}_ is invalid.")
  end

  def validate_every_n_weeks
    return if sup_every_n_weeks >= 1
    errors.add(:sup_every_n_weeks, "Sup every _#{sup_every_n_weeks}_ is invalid, must be at least 1.")
  end

  def validate_sup_size
    return if sup_size >= 2
    errors.add(:sup_size, "Sup for _#{sup_size}_ is invalid, requires at least 2 people to meet.")
  end

  def trial_expired_text
    return unless subscription_expired?
    "Your S'Up bot trial subscription has expired."
  end

  def subscribe_team_text
    "Subscribe your team for $39.99 a year at #{SlackSup::Service.url}/subscribe?team_id=#{team_id}."
  end

  INSTALLED_TEXT =
    "Hi there! I'm your team's S'Up bot. " \
    'Thanks for trying me out. Type `help` for instructions. ' \
    "I plan to setup some S'Ups via Slack DM next Monday.".freeze

  SUBSCRIBED_TEXT =
    "Hi there! I'm your team's S'Up bot. " \
    'Your team has purchased a yearly subscription. ' \
    'Follow us on Twitter at https://twitter.com/playplayio for news and updates. ' \
    'Thanks for being a customer!'.freeze

  def inform_subscribed_changed!
    return unless subscribed? && subscribed_changed?
    inform! SUBSCRIBED_TEXT
  end
end
