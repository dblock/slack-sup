# A single sup between multiple users.
class Sup
  include Mongoid::Document
  include Mongoid::Timestamps

  field :outcome, type: String
  belongs_to :team
  belongs_to :round
  has_and_belongs_to_many :users

  index(round: 1, user_ids: 1)

  PLEASE_SUP_MESSAGE =
    "Hi there! I'm your team's S'Up bot. " \
    'Please find a time for a quick 20 minute break on the calendar. ' \
    "Then get together and tell each other about something awesome you're working on these days.".freeze

  def sup!
    logger.info "Creating S'Up on a DM channel with #{users.map(&:user_name)}."
    dm!(text: Sup::PLEASE_SUP_MESSAGE)
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
            text: "We Couldn't Meet",
            type: 'button',
            value: 'none',
            style: 'danger'
          }
        ]
      }
    ]
  }.freeze

  def ask!
    message = ASK_WHO_SUP_MESSAGE.dup
    message[:attachments].first[:callback_id] = id.to_s
    logger.info "Asking for outcome on a DM channel with #{users.map(&:user_name)}."
    dm!(message)
  end

  def to_s
    "id=#{id}, users=#{users.map(&:user_name).join(', ')}"
  end

  validates_presence_of :team_id
  before_validation :validate_team

  private

  def validate_team
    return if team_id && round.team_id == team_id && users.all? { |user| user.team_id == team_id }
    errors.add(:team, 'Rounds can only be created amongst users of the same team.')
  end

  # creates a DM between all the parties involved
  def dm!(message)
    client = Slack::Web::Client.new(token: round.team.token)
    channel = client.mpim_open(users: users.map(&:user_id).join(','))
    client.chat_postMessage(message.merge(channel: channel.group.id, as_user: true))
  end
end
