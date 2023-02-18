class Member
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :channel

  field :sync, type: Boolean, default: false
  field :user_id, type: String
  field :user_name, type: String
  field :email, type: String
  field :is_organizer, type: Boolean, default: false
  field :is_owner, type: Boolean, default: false
  field :is_admin, type: Boolean, default: false
  field :real_name, type: String

  field :opted_in, type: Boolean, default: true
  scope :opted_in, -> { where(enabled: true, opted_in: true) }
  scope :opted_out, -> { where(enabled: true, opted_in: false) }

  field :enabled, type: Boolean, default: true
  scope :enabled, -> { where(enabled: true) }

  scope :suppable, -> { where(enabled: true, opted_in: true) }
  index(channel_id: 1, enabled: 1, opted_in: 1)
  index({ channel_id: 1, user_id: 1 }, unique: true)

  def slack_client
    channel.slack_client
  end

  def update_info!(info = nil)
    update_attributes!(
      is_organizer: channel.inviter_id == user_id,
      is_admin: info.is_admin,
      is_owner: info.is_owner,
      user_name: info.name,
      real_name: info.real_name,
      email: info.profile&.email,
      sync: false
    )
  end

  def to_s
    "user_name=#{user_name}, user_id=#{user_id}, email=#{email}, real_name=#{real_name}"
  end
end
