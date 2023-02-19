module SlackSup
  module Commands
    class Sync < SlackRubyBot::Commands::Base
      include SlackSup::Commands::Mixins::Subscribe

      channel_command 'sync' do |client, _channel, user, data, _match|
        if user.channel_admin?
          channel.update_attributes!(sync: true)
          client.say(channel: data.channel, text: "#{team.last_sync_at_s}. I have scheduled a user sync in the next hour. Come back and run `stats` in a bit.")
        elsif !v.nil?
          client.say(channel: data.channel, text: "#{team.last_sync_at_s}. Only <@#{team.activated_user_id}> or a Slack team admin can manually sync, sorry.")
        end
        logger.info "SYNC: #{channel} - #{data.user}"
      end
    end
  end
end
