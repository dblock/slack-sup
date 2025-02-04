module SlackSup
  module Commands
    class Demote < SlackRubyBot::Commands::Base
      include SlackSup::Commands::Mixins::Subscribe

      subscribe_command 'demote' do |client, data, match|
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        raise SlackSup::Error, "Sorry, only #{user.team.team_admins_slack_mentions.or} can demote users." unless user.team_admin?

        mention = match['expression']
        raise SlackSup::Error, 'Sorry, demote @someone.' if mention.blank?

        mentioned = User.find_by_slack_mention!(client.owner, mention)
        raise SlackSup::Error, 'Sorry, you cannot demote yourself.' if user == mentioned

        updated = mentioned.is_admin
        mentioned.update_attributes!(is_admin: false) if updated
        client.say(channel: data.channel, text: "User #{mentioned.slack_mention} is #{updated ? 'no longer' : 'not'} S'Up admin.")
        logger.info "DEMOTE: #{client.owner}, user=#{data.user}, #{mentioned}, is_admin=#{mentioned.is_admin}"
      end
    end
  end
end
