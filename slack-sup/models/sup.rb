# A single sup between multiple users.
class Sup
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :round
  has_and_belongs_to_many :users
  has_many :meetings, dependent: :destroy

  index(round: 1, user_ids: 1)

  after_create do
    users.each do |user|
      users.each do |other|
        next if other == user
        Meeting.create!(sup: self, user: user, other: other)
      end
    end
  end

  PLEASE_SUP_MESSAGE =
    "Hi there! I'm your team's S'Up bot. " \
    'Please find a time for a quick 20 minute break on the calendar. ' \
    "Then get together and tell each other about something awesome you're working on these days.".freeze

  # creates a DM between all the parties involved
  def dm!
    client = Slack::Web::Client.new(token: round.team.token)
    logger.info "Creating a DM channel with #{users.map(&:user_name)}."
    channel = client.mpim_open(users: users.map(&:user_id).join(','))
    client.chat_postMessage(text: Sup::PLEASE_SUP_MESSAGE, channel: channel.group.id, as_user: true)
  end

  def to_s
    "id=#{id}, users=#{users.map(&:user_name).join(', ')}"
  end
end
