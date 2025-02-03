class Export
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :team
  field :user_id, type: String

  validates_presence_of :team, :user_id

  field :filename, type: String
  field :exported, type: Boolean, default: false

  scope :requested, -> { where(exported: false) }

  def to_s
    "id=#{id}, #{team}, user_id=#{user_id}, exported=#{exported}"
  end

  def token
    team.token
  end

  def export!
    return if exported?

    Api::Middleware.logger.info "Exporting data for #{self}."
    path = File.join(Dir.tmpdir, 'slack-sup', _id)
    FileUtils.rm_rf(path)
    FileUtils.makedirs(path)
    filename = team.export_zip!(path)
    update_attributes!(filename:, exported: true)
    Api::Middleware.logger.info "Exported data for #{self}, filename=#{filename}."
    notify!
    filename
  end

  def notify!
    team.slack_client.chat_postMessage(
      channel: team.slack_client.conversations_open(users: user_id).channel.id,
      text: 'Click here to download your team data.',
      attachments: [
        {
          text: '',
          attachment_type: 'default',
          actions: [
            {
              type: 'button',
              text: 'Download',
              url: "#{SlackRubyBotServer::Service.url}/api/data/#{_id}?access_token=#{CGI.escape(team.short_lived_token)}"
            }
          ]
        }
      ]
    )
  end
end
