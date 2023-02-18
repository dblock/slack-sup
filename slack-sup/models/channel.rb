class Channel
  include Mongoid::Document
  include Mongoid::Timestamps

  field :channel_id, type: String
  field :inviter_id, type: String
  field :enabled, type: Boolean, default: true
  field :sync, type: Boolean, default: true
  field :last_sync_at, type: DateTime
  field :opt_in, type: Boolean, default: true

  has_many :members
  belongs_to :team

  index({ channel_id: 1, team_id: 1 }, unique: true)

  def opt_in_s
    opt_in? ? 'in' : 'out'
  end

  def slack_client
    team.slack_client
  end

  def sync!
    tt = Time.now.utc
    active_member_ids = slack_client.paginate(:conversations_members, channel: channel_id).map(&:members).flatten
    current_member_ids = members.all.map(&:user_id)
    (current_member_ids - active_member_ids).each do |user_id|
      member = members.where(user_id: user_id).first
      next unless member

      logger.info "Team #{team}: #{member} removed from #{channel_id}."
      member.update_attributes!(enabled: false)
    end
    active_member_ids.each do |user_id|
      info = slack_client.users_info(user: user_id).user
      next if info.is_bot || info.deleted || info.is_restricted || info.is_ultra_restricted || info.id == 'USLACKBOT'

      member = members.where(user_id: user_id).first
      member ||= members.new(user_id: user_id, opted_in: opt_in)
      logger.info "Team #{team}: #{member} #{member.persisted? ? 'added' : 'updated'} in #{channel_id}."
      member.update_info!(info)
    end
    update_attributes!(sync: false, last_sync_at: tt)
  end
end
