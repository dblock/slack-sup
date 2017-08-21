class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: String
  field :user_name, type: String
  field :custom_team_name, type: String
  field :is_admin, type: Boolean, default: false
  field :real_name, type: String

  field :introduced_sup_at, type: DateTime

  field :opted_in, type: Boolean, default: true
  scope :opted_in, -> { where(opted_in: true) }

  field :enabled, type: Boolean, default: true
  scope :enabled, -> { where(enabled: true) }

  scope :suppable, -> { where(enabled: true, opted_in: true) }
  index(team_id: 1, enabled: 1, opted_in: 1)

  belongs_to :team, index: true
  validates_presence_of :team

  index({ user_id: 1, team_id: 1 }, unique: true)
  index(user_name: 1, team_id: 1)

  def slack_mention
    "<@#{user_id}>"
  end

  INTRODUCING_SUP_MESSAGE =
    "Hi there! I'm your team's S'Up bot. " \
    "Once a week I will ask you to setup an informal meeting, or S'Up, short for standup, with a couple randomly chosen colleagues at the company. " \
    "It's a great opportunity for you to share and learn about the many projects we've been working on across organizational boundaries.".freeze

  def introduce_sup!
    return if introduced_sup_at
    client = Slack::Web::Client.new(token: team.token)
    logger.info "Introducing SUP in a DM channel with #{self}."
    channel = client.im_open(user: user_id)
    client.chat_postMessage(text: User::INTRODUCING_SUP_MESSAGE, channel: channel.channel.id, as_user: true)
    update_attributes!(introduced_sup_at: Time.now.utc)
  end

  def self.find_by_slack_mention!(team, user_name)
    user_match = user_name.match(/^<@(.*)>$/)
    query = user_match ? { user_id: user_match[1] } : { user_name: ::Regexp.new("^#{user_name}$", 'i') }
    user = User.where(query.merge(team: team)).first
    raise SlackSup::Error, "I don't know who #{user_name} is!" unless user
    user
  end

  # Find an existing record, update the username if necessary, otherwise create a user record.
  def self.find_create_or_update_by_slack_id!(client, slack_id)
    instance = User.where(team: client.owner, user_id: slack_id).first
    instance_info = Hashie::Mash.new(client.web_client.users_info(user: slack_id)).user
    instance.update_attributes!(is_admin: instance_info.is_admin) if instance && instance.is_admin != instance_info.is_admin
    instance.update_attributes!(user_name: instance_info.name) if instance && instance.user_name != instance_info.name
    instance ||= User.create!(team: client.owner, user_id: slack_id, user_name: instance_info.name)
    instance
  end

  def to_s
    "user_name=#{user_name}, user_id=#{user_id}, real_name=#{real_name}, custom_team_name=#{custom_team_name}"
  end

  def update_custom_profile
    custom_team_name = nil
    return unless team.team_field_label_id
    client = Slack::Web::Client.new(token: team.access_token)
    fields = client.users_profile_get(user: user_id).profile.fields
    custom_field_value = fields[team.team_field_label_id] if fields && fields.is_a?(::Slack::Messages::Message)
    self.custom_team_name = custom_field_value.value if custom_field_value
  end
end
