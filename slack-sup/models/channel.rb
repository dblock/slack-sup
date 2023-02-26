class Channel
  include Mongoid::Document
  include Mongoid::Timestamps
  include SlackSup::Models::Mixins::Pluralize

  field :channel_id, type: String
  field :inviter_id, type: String
  field :enabled, type: Boolean, default: true
  field :opt_in, type: Boolean, default: true

  scope :api, -> { where(api: true) }

  # enable API for this channel
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

  # sync
  field :sync, type: Boolean, default: false
  field :last_sync_at, type: DateTime

  # custom team field
  field :team_field_label, type: String
  field :team_field_label_id, type: String

  has_many :users
  has_many :rounds, dependent: :destroy
  has_many :sups, dependent: :destroy

  before_validation :validate_team_field_label
  before_validation :validate_team_field_label_id
  before_validation :validate_sup_time_of_day
  before_validation :validate_sup_every_n_weeks
  before_validation :validate_sup_size
  before_validation :validate_sup_recency

  belongs_to :team

  index({ channel_id: 1, team_id: 1 }, unique: true)

  index({ enabled: 1 })
  scope :enabled, -> { where(enabled: true) }

  def short_lived_token
    JWT.encode({ dt: Time.now.utc.to_i, nonce: SecureRandom.hex }, team.token)
  end

  def short_lived_token_valid?(short_lived_token, dt = 30.minutes)
    return false unless short_lived_token

    data, = JWT.decode(short_lived_token, team.token)
    Time.at(data['dt']).utc + dt >= Time.now.utc
  rescue JWT::DecodeError
    false
  end

  def api_url
    return unless api?

    "#{SlackRubyBotServer::Service.api_url}/channels/#{id}"
  end

  def api_s
    api? ? 'on' : 'off'
  end

  def opt_in_s
    opt_in? ? 'in' : 'out'
  end

  def opt_in_s
    opt_in? ? 'in' : 'out'
  end

  def slack_mention
    "<##{channel_id}>"
  end

  def slack_client
    team.slack_client
  end

  def find_user_by_slack_mention!(user_name)
    user_match = user_name.match(/^<@(.*)>$/)
    user = if user_match
             find_or_create_user!(user_match[1])
           else
             users.where({ user_name: ::Regexp.new("^#{user_name}$", 'i') }).first
           end

    raise SlackSup::Error, "I don't know who #{user_name} is!" unless user

    user
  end

  def self.parse_slack_mention(mention)
    channel_match = mention.match(/^<#(.*)>$/)
    channel_match[1] if channel_match
  end

  def self.parse_slack_mention!(mention)
    parse_slack_mention(mention) || raise(SlackSup::Error, "Invalid channel mention #{mention}.")
  end

  def find_or_create_user!(user_id)
    user = users.where(user_id: user_id).first
    user || users.create!(user_id: user_id, sync: true, opted_in: opt_in)
  end

  def sync!
    tt = Time.now.utc
    updated_user_ids = []
    slack_client.conversations_members(channel: channel_id) do |page|
      page.members.each do |user_id|
        user_info = slack_client.users_info(user: user_id).user
        existing_user = users.where(user_id: user_id).first
        if User.suppable_user?(user_info)
          if existing_user
            existing_user.enabled = true
            existing_user.update_info_attributes!(user_info)
            logger.info "Team #{team}: #{existing_user} updated in #{channel_id}."
            updated_user_ids << existing_user.id
          else
            new_user = users.new(user_id: user_id, opted_in: opt_in)
            new_user.update_info_attributes!(user_info)
            logger.info "Team #{team}: #{new_user} added to #{channel_id}."
            updated_user_ids << new_user.id
          end
        elsif existing_user
          existing_user.enabled = false
          existing_user.update_info_attributes!(user_info)
          logger.info "Team #{team}: #{existing_user} disabled in #{channel_id}."
          updated_user_ids << existing_user.id
        else
          logger.info "Team #{team}: #{user_info.user_name}, #{user_info.user_id} skipped in #{channel_id}."
        end
      end
    end
    users.where(:_id.nin => updated_user_ids).each do |existing_user|
      logger.info "Team #{team}: #{existing_user} disabled in #{channel_id}."
      existing_user.update_attributes!(enabled: false)
    end
    update_attributes!(sync: false, last_sync_at: tt)
  end

  def to_s
    "#{team}, channel_id=#{channel_id}"
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
    return false unless team.active?

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

  def next_sup_at_text
    [
      "Next round in #{slack_mention} is",
      Time.now > next_sup_at ? 'overdue' : nil,
      next_sup_at.strftime('%A, %B %e, %Y at %l:%M %p %Z').gsub('  ', ' '),
      '(' + next_sup_at.to_time.ago_or_future_in_words(highest_measure_only: true) + ').'
    ].compact.join(' ')
  end

  def last_sync_at_text
    tt = last_sync_at || last_round_at
    messages = []
    if tt
      updated_users_count = users.where(:updated_at.gte => last_sync_at).count
      messages << "Last users sync was #{tt.to_time.ago_in_words}, #{pluralize(updated_users_count, 'user')} updated."
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

  def validate_team_field_label
    return unless team_field_label && team_field_label_changed?

    profile_fields = team.slack_client_with_activated_user_access.team_profile_get.profile.fields
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
    return if sup_time_of_day && sup_time_of_day >= 0 && sup_time_of_day < 24 * 60 * 60

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
end
