class Team
  field :stripe_customer_id, type: String
  field :subscribed, type: Boolean, default: false
  field :subscribed_at, type: DateTime

  scope :api, -> { where(api: true) }

  # enable API for this team
  field :api, type: Boolean, default: false
  field :api_token, type: String

  has_many :channels, dependent: :destroy

  after_update :subscribed!
  after_save :activated!

  def rounds
    Round.where(:channel_id.in => channels.distinct(:_id))
  end

  def sups
    Sup.where(:channel_id.in => channels.distinct(:_id))
  end

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

  def is_admin?(user_id)
    return true if activated_user_id == user_id

    user_info = slack_client.users_info(user: user_id).user
    return true if user_info.is_admin? || user_info.is_owner?

    false
  end

  def asleep?(dt = 3.weeks)
    return false unless subscription_expired?

    time_limit = Time.now.utc - dt
    created_at <= time_limit
  end

  def inform!(message)
    members = slack_client.users_list(presence: false).map(&:members).flatten
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

  def slack_client
    @client ||= Slack::Web::Client.new(token: token)
  end

  def slack_client_with_activated_user_access
    @slack_client_with_activated_user_access ||= Slack::Web::Client.new(token: activated_user_access_token)
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

  def stripe_customer_text
    "Customer since #{Time.at(stripe_customer.created).strftime('%B %d, %Y')}."
  end

  def subscriber_text
    return unless subscribed_at

    "Subscriber since #{subscribed_at.strftime('%B %d, %Y')}."
  end

  def enabled_channels_text
    enabled_channels = channels.enabled.to_a
    if enabled_channels.count == 0
      "S'Up is not enabled in any channels."
    elsif enabled_channels.count == 1
      "S'Up is enabled in #{enabled_channels.first.slack_mention}."
    else
      "S'Up is enabled in #{enabled_channels.count} channels (#{enabled_channels.map(&:slack_mention).and})."
    end
  end

  def stripe_customer_subscriptions_info(with_unsubscribe = false)
    stripe_customer.subscriptions.map do |subscription|
      amount = ActiveSupport::NumberHelper.number_to_currency(subscription.plan.amount.to_f / 100)
      current_period_end = Time.at(subscription.current_period_end).strftime('%B %d, %Y')
      [
        "Subscribed to #{subscription.plan.name} (#{amount}), will#{subscription.cancel_at_period_end ? ' not' : ''} auto-renew on #{current_period_end}.",
        !subscription.cancel_at_period_end && with_unsubscribe ? "Send `unsubscribe #{subscription.id}` to unsubscribe." : nil
      ].compact.join("\n")
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

  def find_create_or_update_channel_by_channel_id!(channel_id, user_id)
    raise 'missing channel_id' unless channel_id
    return nil if channel_id[0] == 'D'

    channel = channels.where(channel_id: channel_id).first
    channel ||= channels.create!(channel_id: channel_id, enabled: true, sync: true, inviter_id: user_id)
    channel
  end

  def find_create_or_update_user_in_channel_by_slack_id!(channel_id, user_id)
    channel = find_create_or_update_channel_by_channel_id!(channel_id, user_id)
    channel ? channel.find_or_create_user!(user_id) : user_id
  end

  def join_channel!(channel_id, inviter_id)
    channel = channels.where(channel_id: channel_id).first
    channel ||= channels.create!(channel_id: channel_id)
    channel.update_attributes!(enabled: true, sync: true, inviter_id: inviter_id)
    channel
  end

  def leave_channel!(channel_id)
    channel = channels.where(channel_id: channel_id).first
    channel&.update_attributes!(enabled: false, sync: false)
    channel || false
  end

  def api_url
    return unless api?

    "#{SlackRubyBotServer::Service.api_url}/teams/#{id}"
  end

  def api_s
    api? ? 'on' : 'off'
  end

  private

  INSTALLED_TEXT =
    "Hi there! I'm your team's S'Up bot. " \
    'Thanks for trying me out. ' \
    'To start, invite me to a channel. ' \
    'You can always DM me `help` for instructions.'.freeze

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
