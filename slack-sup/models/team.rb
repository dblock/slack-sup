class Team
  # enable API for this team
  field :api, type: Boolean, default: false

  # sup day of the week, defaults to Monday
  field :sup_wday, type: Integer, default: 1

  field :stripe_customer_id, type: String
  field :subscribed, type: Boolean, default: false
  field :subscribed_at, type: DateTime

  scope :api, -> { where(api: true) }

  has_many :users, dependent: :destroy
  has_many :rounds, dependent: :destroy

  after_update :inform_subscribed_changed!

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
    users.suppable.each(&:introduce_sup!)
    rounds.create!
  end

  def last_sup
    rounds.desc(:created_at).first
  end

  def last_sup_at
    sup = last_sup
    sup ? sup.created_at : nil
  end

  def sup_day
    Date::DAYNAMES[sup_wday]
  end

  # is it time to sup?
  def sup?(dt = 1.week)
    # only sup on a certain day of the week
    return false unless Time.now.utc.wday == sup_wday
    # don't sup more than once a week
    time_limit = Time.now.utc - dt
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
    "I'm going to setup some S'Ups via Slack DM shortly.".freeze

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
