module SlackSup
  module Commands
    class Data < SlackRubyBot::Commands::Base
      include SlackSup::Commands::Mixins::Subscribe

      subscribe_command 'data' do |client, data, _match|
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        raise SlackSup::Error, "Sorry, only #{user.team.team_admins_slack_mentions.or} can download data." unless user.team_admin?
        raise SlackSup::Error, "Hey <@#{data.user}>, we are still working on your previous request." if Export.where(team: client.owner, user_id: data.user, exported: false).exists?

        Export.create!(
          team: client.owner,
          user_id: data.user
        )

        client.say(channel: data.channel, text: "Hey #{user.slack_mention}, we will prepare your team data in the next few minutes, please check your DMs for a link.")
        logger.info "DATA: #{data.team}, user=#{data.user}"
      end
    end
  end
end
