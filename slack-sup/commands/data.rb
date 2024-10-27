module SlackSup
  module Commands
    class Data < SlackRubyBot::Commands::Base
      include SlackSup::Commands::Mixins::Subscribe

      subscribe_command 'data' do |client, data, _match|
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        raise SlackSup::Error, "Sorry, only #{user.team.team_admins_slack_mentions} can download data." unless user.team_admin?

        dm = client.owner.slack_client.conversations_open(users: data.user)
        client.owner.slack_client.chat_postMessage(
          channel: dm.channel.id,
          as_user: true,
          text: 'Click here to download your team data.',
          attachments: [
            {
              text: '',
              attachment_type: 'default',
              actions: [
                {
                  type: 'button',
                  text: 'Download',
                  url: "#{SlackRubyBotServer::Service.url}/api/data?team_id=#{client.owner.id}&access_token=#{CGI.escape(client.owner.short_lived_token)}"
                }
              ]
            }
          ]
        )

        client.say(channel: data.channel, text: "Hey #{user.slack_mention}, check your DMs for a link.") unless data.channel[0] == 'D'
        logger.info "DATA: #{data.team}, user=#{data.user}"
      end
    end
  end
end
