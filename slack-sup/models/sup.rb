# A single sup between multiple users.
class Sup
  include Mongoid::Document
  include Mongoid::Timestamps

  field :outcome, type: String
  field :channel_id, type: String
  field :gcal_html_link, type: String
  belongs_to :team
  belongs_to :round
  has_and_belongs_to_many :users

  belongs_to :captain, class_name: 'User', inverse_of: nil, optional: true

  index(round: 1, user_ids: 1)

  HI_MESSAGE = "Hi there! I'm your team's S'Up bot.".freeze

  PLEASE_SUP_MESSAGE =
    'Please find a time for a quick 20 minute break on the calendar. ' \
    "Then get together and tell each other about something awesome you're working on these days.".freeze

  def sup!
    logger.info "Creating S'Up on a DM channel with #{users.map(&:user_name)}."
    update_attributes!(captain: select_best_captain)
    messages = [
      HI_MESSAGE,
      intro_message,
      team.sup_message || PLEASE_SUP_MESSAGE,
      captain && "#{captain.slack_mention}, you're in charge this week to make it happen!"
    ].compact
    dm!(text: messages.join("\n\n"))
    users.each do |user|
      next if user.introduced_sup?

      user.update_attributes!(introduced_sup_at: Time.now.utc)
    end
  end

  ASK_WHO_SUP_MESSAGE = {
    text: 'I just wanted to check in, how did it go?',
    attachments: [
      {
        text: '',
        attachment_type: 'default',
        actions: [
          {
            name: 'outcome',
            text: 'We All Met',
            type: 'button',
            value: 'all',
            style: 'primary'
          },
          {
            name: 'outcome',
            text: 'Some of Us Met',
            type: 'button',
            value: 'some'
          },
          {
            name: 'outcome',
            text: "We Haven't Met Yet",
            type: 'button',
            value: 'later',
            style: 'danger'
          },
          {
            name: 'outcome',
            text: "We Couldn't Meet",
            type: 'button',
            value: 'none',
            style: 'danger'
          }
        ]
      }
    ]
  }.freeze

  ASK_WHO_SUP_AGAIN_MESSAGE = {
    text: 'I just wanted to check in one last time, how did it go?',
    attachments: [
      {
        text: '',
        attachment_type: 'default',
        actions: [
          {
            name: 'outcome',
            text: 'We All Met',
            type: 'button',
            value: 'all',
            style: 'primary'
          },
          {
            name: 'outcome',
            text: 'Some of Us Met',
            type: 'button',
            value: 'some'
          },
          {
            name: 'outcome',
            text: "We Couldn't Meet",
            type: 'button',
            value: 'none',
            style: 'danger'
          }
        ]
      }
    ]
  }.freeze

  RESPOND_TO_ASK_MESSAGES = {
    'all' => 'Glad you all met! Thanks for letting me know.',
    'some' => 'Glad to hear that some of you could meet! Thanks for letting me know.',
    'later' => "Thanks, I'll ask again in a couple of days.",
    'none' => "Sorry to hear that you couldn't meet. Thanks for letting me know."
  }.freeze

  def ask!
    message = ASK_WHO_SUP_MESSAGE.dup
    message[:attachments].first[:callback_id] = id.to_s
    logger.info "Asking for outcome on a DM channel with #{users.map(&:user_name)}."
    dm!(message)
  end

  def ask_again!
    message = ASK_WHO_SUP_AGAIN_MESSAGE.dup
    message[:attachments].first[:callback_id] = id.to_s
    logger.info "Asking again for outcome on a DM channel with #{users.map(&:user_name)}."
    dm!(message)
  end

  def remind!
    return unless channel_id

    messages = slack_client.conversations_history(channel: channel_id, limit: 3).messages
    return unless messages.size <= 1

    dm!(text: captain ? "Bumping myself on top of your list, #{captain.slack_mention}." : 'Bumping myself on top of your list.')
  end

  def to_s
    "id=#{id}, users=#{users.map(&:user_name).and}"
  end

  def calendar_href(dt = nil)
    "#{SlackRubyBotServer::Service.url}/gcal?sup_id=#{id}&dt=#{dt ? dt.to_i : nil}&access_token=#{team.short_lived_token}"
  end

  validates_presence_of :team_id
  before_validation :validate_team
  after_save :notify_gcal_html_link_changed!

  def captain_user_name
    captain&.user_name
  end

  private

  def notify_gcal_html_link_changed!
    return unless gcal_html_link && (gcal_html_link_changed? || saved_change_to_gcal_html_link?)

    dm!(text: "I've added this S'Up to your Google Calendar: #{gcal_html_link}")
  end

  def select_best_captain
    users.min_by do |u|
      return u if u.last_captain_at.nil?

      u.last_captain_at
    end
  end

  def intro_message
    new_users = users.reject(&:introduced_sup?)
    return unless new_users.any?

    [
      team.sup_size == 3 ? 'The most valuable relationships are not made of 2 people, they’re made of 3.' : nil,
      "Team S'Up connects groups of #{team.sup_size} people on #{team.sup_day} every #{team.sup_every_n_weeks_s}.",
      "Welcome #{new_users.sort_by(&:id).map(&:slack_mention).and}, excited for your first S'Up!"
    ].compact.join(' ')
  end

  def validate_team
    return if team_id && round.team_id == team_id && users.all? { |user| user.team_id == team_id }

    errors.add(:team, 'Rounds can only be created amongst users of the same team.')
  end

  def slack_client
    round.team.slack_client
  end

  # creates a DM between all the parties involved
  def dm!(message)
    unless channel_id
      channel = slack_client.conversations_open(users: users.map(&:user_id).join(','))
      update_attributes!(channel_id: channel.channel.id)
    end
    slack_client.chat_postMessage(message.merge(channel: channel_id, as_user: true))
  end
end
