class Team
  field :api, type: Boolean, default: false

  field :stripe_customer_id, type: String
  field :subscribed, type: Boolean, default: false
  field :subscribed_at, type: DateTime

  scope :api, -> { where(api: true) }

  has_many :users

  after_update :inform_subscribed_changed!

  def asleep?(dt = 2.weeks)
    return false unless subscription_expired?
    time_limit = Time.now - dt
    created_at <= time_limit
  end

  def inform!(message)
    client = Slack::Web::Client.new(token: token)
    channels = client.channels_list['channels'].select { |channel| channel['is_member'] }
    return unless channels.any?
    channel = channels.first
    logger.info "Sending '#{message}' to #{self} on ##{channel['name']}."
    client.chat_postMessage(text: message, channel: channel['id'], as_user: true)
  end

  def subscription_expired?
    return false if subscribed?
    (created_at + 1.week) < Time.now
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
      !member.is_bot && !member.deleted && member.id != 'USLACKBOT'
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
    'Your trial subscription has expired.'
  end

  def subscribe_team_text
    "Subscribe your team for $39.99 a year at #{SlackSup::Service.url}/subscribe?team_id=#{team_id}."
  end

  SUBSCRIBED_TEXT = <<~EOS.freeze
    Your team has been subscribed. Thanks for being a customer!
    Follow https://twitter.com/playplayio for news and updates.
EOS

  def inform_subscribed_changed!
    return unless subscribed? && subscribed_changed?
    inform! SUBSCRIBED_TEXT
  end
end
