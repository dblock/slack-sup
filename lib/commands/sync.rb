module SlackSup
  module Commands
    class Sync < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackSup::Commands::Mixins::User

      user_command 'sync' do |channel, user, data|
        if channel && user.channel_admin?
          channel.update_attributes!(sync: true)
          data.team.slack_client.chat_postMessage(channel: data.channel, text: "#{channel.last_sync_at_text} Come back and run `stats` in a bit.")
        elsif channel
          data.team.slack_client.chat_postMessage(channel: data.channel, text: "Users will sync before the next round. Only <@#{channel.inviter_id}> or a Slack team admin can manually sync, sorry.")
        else
          data.team.slack_client.chat_postMessage(channel: data.channel, text: 'Please run this command in a channel.')
        end
        logger.info "SYNC: #{data.team}, #{channel}, user=#{data.user}"
      end
    end
  end
end
