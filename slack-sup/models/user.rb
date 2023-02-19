class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :sync, type: Boolean, default: false
  field :last_sync_at, type: DateTime

  field :user_id, type: String
  field :user_name, type: String
  field :email, type: String
  field :custom_team_name, type: String
  field :is_organizer, type: Boolean, default: false
  field :is_owner, type: Boolean, default: false
  field :is_admin, type: Boolean, default: false
  field :real_name, type: String

  field :introduced_sup_at, type: DateTime

  field :opted_in, type: Boolean, default: true
  scope :opted_in, -> { where(enabled: true, opted_in: true) }
  scope :opted_out, -> { where(enabled: true, opted_in: false) }

  field :enabled, type: Boolean, default: true
  scope :enabled, -> { where(enabled: true) }

  scope :suppable, -> { where(enabled: true, opted_in: true) }
  index(channel_id: 1, enabled: 1, opted_in: 1)

  belongs_to :channel, index: true
  validates_presence_of :channel

  index({ user_id: 1, channel_id: 1 }, unique: true)
  index(user_name: 1, channel_id: 1)

  def slack_client
    channel.slack_client
  end

  def activated_user?
    channel.team.activated_user_id && channel.team.activated_user_id == user_id
  end

  def team_admin?
    activated_user? || is_admin? || is_owner?
  end

  def channel_admin?
    user_id == channel.inviter_id || team_admin?
  end

  def slack_mention
    "<@#{user_id}>"
  end

  def introduced_sup?
    !introduced_sup_at.nil?
  end

  def last_captain_at
    last_captain_sup = channel.sups.where(captain_id: id).desc(:created_at).limit(1).first
    last_captain_sup&.created_at
  end

  def update_info_attributes!(info)
    update_attributes!(
      is_organizer: channel.inviter_id == user_id,
      is_admin: info.is_admin,
      is_owner: info.is_owner,
      user_name: info.name,
      real_name: info.real_name,
      email: info.profile&.email,
      sync: false,
      last_sync_at: Time.now.utc,
      custom_team_name: get_team_name
    )
  end

  def sync!
    tt = Time.now.utc
    info = slack_client.users_info(user: user_id).user
    update_info_attributes!(info)
  end

  def to_s
    "user_name=#{user_name}, user_id=#{user_id}, email=#{email}, real_name=#{real_name}, custom_team_name=#{custom_team_name}"
  end

  def self.suppable_user?(user_info)
    !user_info.is_bot &&
      !user_info.deleted &&
      !user_info.is_restricted &&
      !user_info.is_ultra_restricted &&
      !on_vacation?(user_info) &&
      user_info.id != 'USLACKBOT'
  end

  def self.on_vacation?(user_info)
    [user_info.name, user_info.real_name, user_info&.profile&.status_text].compact.join =~ /(ooo|vacationing)/i
  end

  private

  def get_team_name
    return unless channel.team_field_label_id

    fields = channel.team.slack_client_with_activated_user_access.users_profile_get(user: user_id).profile.fields
    custom_field_value = fields[channel.team_field_label_id] if fields&.is_a?(::Slack::Messages::Message)
    custom_field_value&.value
  rescue Exception => e
    logger.warn "Error getting custom team name for #{self}, #{e.message}."
    nil
  end
end
