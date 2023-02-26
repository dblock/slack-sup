module SlackSup
  module Commands
    class Sync < SlackRubyBot::Commands::Base
      include SlackSup::Commands::Mixins::User

      user_command 'sync' do |client, channel, user, data, _match|
        if channel && user.channel_admin?
          channel.update_attributes!(sync: true)
          client.say(channel: data.channel, text: "#{channel.last_sync_at_text} Come back and run `stats` in a bit.")
        elsif channel
          client.say(channel: data.channel, text: "Users will sync before the next round. Only <@#{channel.inviter_id}> or a Slack team admin can manually sync, sorry.")
        else
          client.say(channel: data.channel, text: 'Please run this command in a channel.')
        end
        logger.info "SYNC: #{client.owner}, #{channel}, user=#{data.user}"
      end
    end
  end
end
