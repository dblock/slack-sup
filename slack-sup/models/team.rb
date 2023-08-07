class Team
  # enable API for this team
  field :api, type: Boolean, default: false
  field :api_token, type: String

  # sup size
  field :sup_size, type: Integer, default: 3
  # sup remaining odd users
  field :sup_odd, type: Boolean, default: true
  # sup frequency in weeks
  field :sup_time_of_day, type: Integer, default: 9 * 60 * 60
  field :sup_every_n_weeks, type: Integer, default: 1
  field :sup_recency, type: Integer, default: 12
  # sup day of the week, defaults to Monday
  field :sup_wday, type: Integer, default: 1
  # sup day of the week we ask for sup results, defaults to Thursday
  field :sup_followup_wday, type: Integer, default: 4
  field :sup_tz, type: String, default: 'Eastern Time (US & Canada)'
  validates_presence_of :sup_tz

  field :sup_message, type: String

  field :opt_in, type: Boolean, default: true

  # sync
  field :sync, type: Boolean, default: false
  field :last_sync_at, type: DateTime

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

  after_update :subscribed!
  after_save :activated!

  before_validation :validate_team_field_label
  before_validation :validate_team_field_label_id
  before_validation :validate_sup_time_of_day
  before_validation :validate_sup_every_n_weeks
  before_validation :validate_sup_size
  before_validation :validate_sup_recency

  def tags
    [
      subscribed? ? 'subscribed' : 'trial',
      stripe_customer_id? ? 'paid' : nil
    ].compact
  end

  def bot_name
    client = server.send(:client) if server
    name = client.self.name if client&.self
    name ||= 'sup'
    "@#{name}"
  end

  def api_url
    return unless api?

    "#{SlackRubyBotServer::Service.api_url}/teams/#{id}"
  end

  def short_lived_token
    JWT.encode({ dt: Time.now.utc.to_i }, token)
  end

  def short_lived_token_valid?(short_lived_token, dt = 30.minutes)
    return false unless short_lived_token

    data, = JWT.decode(short_lived_token, token)
    Time.at(data['dt']).utc + dt >= Time.now.utc
  end

  def api_s
    api? ? 'on' : 'off'
  end

  def opt_in_s
    opt_in? ? 'in' : 'out'
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
    round = last_round
    return unless round&.ask?

    round.ask!
    round
  end

  def ask_again!
    round = last_round
    return unless round&.ask_again?

    round.ask_again!
    round
  end

  def remind!
    round = last_round
    return unless round&.remind?

    round.remind!
    round
  end

  def last_round
    rounds.desc(:created_at).first
  end

  def last_round_at
    round = last_round
    round ? round.created_at : nil
  end

  def sup_time_of_day_s
    Time.at(sup_time_of_day).utc.strftime('%l:%M %p').strip
  end

  def sup_every_n_weeks_s
    sup_every_n_weeks == 1 ? 'week' : "#{sup_every_n_weeks} weeks"
  end

  def sup_recency_s
    sup_recency == 1 ? 'week' : "#{sup_recency} weeks"
  end

  def sup_day
    Date::DAYNAMES[sup_wday]
  end

  def sup_followup_day
    Date::DAYNAMES[sup_followup_wday]
  end

  def sup_tzone
    ActiveSupport::TimeZone.new(sup_tz)
  end

  def sup_tzone_s
    Time.now.in_time_zone(sup_tzone).strftime('%Z')
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
    (last_round_at || time_limit) <= time_limit
  end

  def next_sup_at
    now_in_tz = Time.now.utc.in_time_zone(sup_tzone)
    loop do
      time_limit = now_in_tz.end_of_day - sup_every_n_weeks.weeks

      return now_in_tz.beginning_of_day + sup_time_of_day if (now_in_tz.wday == sup_wday) &&
                                                             ((last_round_at || time_limit) <= time_limit)

      now_in_tz = now_in_tz.beginning_of_day + 1.day
    end
  end

  def inform!(message)
    members = slack_client.paginate(:users_list, presence: false).map(&:members).flatten
    members.select(&:is_admin).each do |admin|
      channel = slack_client.conversations_open(users: admin.id.to_s)
      logger.info "Sending DM '#{message}' to #{admin.name}."
      slack_client.chat_postMessage(text: message, channel: channel.channel.id, as_user: true)
    end
  end

  def subscription_expired?
    return false if subscribed?

    (created_at + 2.weeks) < Time.now
  end

  def update_cc_text
    "Update your credit card info at #{SlackRubyBotServer::Service.url}/update_cc?team_id=#{team_id}."
  end

  def sync_user!(id)
    member = slack_client.users_info(user: id).user
    return unless active_member?(member)

    human = sync_member_from_slack!(member)
    state = if human.persisted?
              human.enabled? ? 'active' : 'back'
            else
              'new'
            end
    logger.info "Team #{self}: #{human} is #{state}."
    human.enabled = true
    human.save!
  rescue StandardError => e
    logger.warn "Error synchronizing user for #{self}, id=#{id}: #{e.message}."
  end

  # synchronize users with slack
  def sync!
    tt = Time.now.utc
    members = slack_client.paginate(:users_list, presence: false).map(&:members).flatten
    humans = members.select { |member| active_member?(member) }.map do |member|
      sync_member_from_slack!(member)
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
    update_attributes!(sync: false, last_sync_at: tt)
  end

  def slack_client
    @client ||= Slack::Web::Client.new(token: token)
  end

  def stripe_customer
    return unless stripe_customer_id

    @stripe_customer ||= Stripe::Customer.retrieve(stripe_customer_id)
  end

  def active_stripe_subscription?
    !active_stripe_subscription.nil?
  end

  def active_stripe_subscription
    return unless stripe_customer

    stripe_customer.subscriptions.detect do |subscription|
      subscription.status == 'active' && !subscription.cancel_at_period_end
    end
  end

  def stripe_subcriptions
    return unless stripe_customer

    stripe_customer.subscriptions
  end

  def stripe_customer_text
    "Customer since #{Time.at(stripe_customer.created).strftime('%B %d, %Y')}."
  end

  def subscriber_text
    return unless subscribed_at

    "Subscriber since #{subscribed_at.strftime('%B %d, %Y')}."
  end

  def stripe_customer_subscriptions_info(with_unsubscribe = false)
    stripe_customer.subscriptions.map do |subscription|
      amount = ActiveSupport::NumberHelper.number_to_currency(subscription.plan.amount.to_f / 100)
      current_period_end = Time.at(subscription.current_period_end).strftime('%B %d, %Y')
      if subscription.status == 'active'
        [
          "Subscribed to #{subscription.plan.name} (#{amount}), will#{subscription.cancel_at_period_end ? ' not' : ''} auto-renew on #{current_period_end}.",
          !subscription.cancel_at_period_end && with_unsubscribe ? "Send `unsubscribe #{subscription.id}` to unsubscribe." : nil
        ].compact.join("\n")
      else
        "#{subscription.status.titleize} subscription created #{Time.at(subscription.created).strftime('%B %d, %Y')} to #{subscription.plan.name} (#{amount})."
      end
    end
  end

  def stripe_customer_invoices_info
    stripe_customer.invoices.map do |invoice|
      amount = ActiveSupport::NumberHelper.number_to_currency(invoice.amount_due.to_f / 100)
      "Invoice for #{amount} on #{Time.at(invoice.date).strftime('%B %d, %Y')}, #{invoice.paid ? 'paid' : 'unpaid'}."
    end
  end

  def stripe_customer_sources_info
    stripe_customer.sources.map do |source|
      "On file #{source.brand} #{source.object}, #{source.name} ending with #{source.last4}, expires #{source.exp_month}/#{source.exp_year}."
    end
  end

  def trial_ends_at
    raise 'Team is subscribed.' if subscribed?

    created_at + 2.weeks
  end

  def remaining_trial_days
    raise 'Team is subscribed.' if subscribed?

    [0, (trial_ends_at.to_date - Time.now.utc.to_date).to_i].max
  end

  def trial_message
    [
      remaining_trial_days.zero? ? 'Your trial subscription has expired.' : "Your trial subscription expires in #{remaining_trial_days} day#{remaining_trial_days == 1 ? '' : 's'}.",
      subscribe_text
    ].join(' ')
  end

  def subscribe_text
    "Subscribe your team for $39.99 a year at #{SlackRubyBotServer::Service.url}/subscribe?team_id=#{team_id}."
  end

  def next_sup_at_text
    [
      'Next round is',
      Time.now > next_sup_at ? 'overdue' : nil,
      next_sup_at.strftime('%A, %B %e, %Y at %l:%M %p %Z').gsub('  ', ' '),
      '(' + next_sup_at.to_time.ago_or_future_in_words(highest_measure_only: true) + ').'
    ].compact.join(' ')
  end

  def last_sync_at_text
    tt = last_sync_at || last_round_at
    messages = []
    if tt
      messages << "Last users sync was #{tt.to_time.ago_in_words}."
      users = self.users.where(:updated_at.gte => last_sync_at)
      messages << "#{pluralize(users.count, 'user')} updated."
    end
    if sync
      messages << 'Users will sync in the next hour.'
    else
      messages << 'Users will sync before the next round.'
      messages << next_sup_at_text
    end
    messages.compact.join(' ')
  end

  private

  def pluralize(count, text)
    case count
    when 0
      "No #{text.pluralize}"
    when 1
      "#{count} #{text}"
    else
      "#{count} #{text.pluralize}"
    end
  end

  def sync_member_from_slack!(member)
    existing_user = User.where(user_id: member.id).first
    existing_user ||= User.new(user_id: member.id, team: self, opted_in: opt_in)
    existing_user.user_name = member.name
    existing_user.real_name = member.real_name
    existing_user.email = member.profile.email if member.profile
    begin
      existing_user.update_custom_profile
    rescue StandardError => e
      logger.warn "Error updating custom profile for #{existing_user}: #{e.message}."
    end
    existing_user
  end

  def active_member?(member)
    !member.is_bot &&
      !member.deleted &&
      !member.is_restricted &&
      !member.is_ultra_restricted &&
      !on_vacation?(member) &&
      member.id != 'USLACKBOT'
  end

  def on_vacation?(member)
    [member.name, member.real_name, member&.profile&.status_text].compact.join =~ /(ooo|vacationing)/i
  end

  def validate_team_field_label
    return unless team_field_label && team_field_label_changed?

    client = Slack::Web::Client.new(token: activated_user_access_token)
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

    errors.add(:sup_time_of_day, "S'Up time of day _#{sup_time_of_day}_ is invalid.")
  end

  def validate_sup_every_n_weeks
    return if sup_every_n_weeks >= 1

    errors.add(:sup_every_n_weeks, "S'Up every _#{sup_every_n_weeks}_ is invalid, must be at least 1.")
  end

  def validate_sup_recency
    return if sup_recency >= 1

    errors.add(:sup_recency, "Don't S'Up with the same people more than every _#{sup_recency_s}_ is invalid, must be at least 1.")
  end

  def validate_sup_size
    return if sup_size >= 2

    errors.add(:sup_size, "S'Up for _#{sup_size}_ is invalid, requires at least 2 people to meet.")
  end

  INSTALLED_TEXT =
    "Hi there! I'm your team's S'Up bot. " \
    'Thanks for trying me out. Type `help` for instructions. ' \
    "I plan to setup some S'Ups via Slack DM next Monday. " \
    'You may want to `set size`, `set day`, `set timezone`, or `set sync now` users before then.'.freeze

  SUBSCRIBED_TEXT =
    "Hi there! I'm your team's S'Up bot. " \
    'Your team has purchased a yearly subscription. ' \
    'Follow us on Twitter at https://twitter.com/playplayio for news and updates. ' \
    'Thanks for being a customer!'.freeze

  def subscribed!
    return unless subscribed? && subscribed_changed?

    inform! SUBSCRIBED_TEXT
  end

  def activated!
    return unless active? && activated_user_id && bot_user_id
    return unless active_changed? || activated_user_id_changed?
  end
end
