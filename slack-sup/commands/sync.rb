module SlackSup
  module Commands
    class Sync < SlackRubyBot::Commands::Base
      include SlackSup::Commands::Mixins::Subscribe

      subscribe_command 'sync' do |client, data, _match|
        team = client.owner
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        if user.team_admin?
          team.update_attributes!(sync: true)
          client.say(channel: data.channel, text: "#{team.last_sync_at_s}. I have scheduled a user sync in the next hour. Come back and run `stats` in a bit.")
        elsif !v.nil?
          client.say(channel: data.channel, text: "#{team.last_sync_at_s}. Only <@#{team.activated_user_id}> or a Slack team admin can manually sync, sorry.")
        end
        logger.info "SYNC: #{client.owner} - #{data.user}"
      end
    end
  end
end
