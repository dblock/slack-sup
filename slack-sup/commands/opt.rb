module SlackSup
  module Commands
    class Opt < SlackRubyBot::Commands::Base
      include SlackSup::Commands::Mixins::Subscribe

      subscribe_command 'opt' do |client, data, match|
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        expression, mention = match['expression'].split(/[\s]+/, 2) if match['expression']
        if mention
          raise SlackSup::Error, "Sorry, only #{user.team.team_admins_slack_mentions} can opt users in and out." unless user.team_admin?

          user = User.find_by_slack_mention!(client.owner, mention)
        end
        case expression
        when 'in' then
          user.update_attributes!(opted_in: true)
        when 'out' then
          user.update_attributes!(opted_in: false)
        when nil, '' then
          # ignore
        else
          mention = " #{mention}" if mention
          raise SlackSup::Error, "You can _opt in#{mention}_ or _opt out#{mention}_, but not _opt #{expression}#{mention}_."
        end
        if mention
          client.say(channel: data.channel, text: "User #{user.slack_mention} is #{expression ? 'now ' : ''}opted #{user.opted_in? ? 'into' : 'out of'} S'Up.")
        else
          client.say(channel: data.channel, text: "Hi there #{user.slack_mention}, you're #{expression ? 'now ' : ''}opted #{user.opted_in? ? 'into' : 'out of'} S'Up.")
        end
        logger.info "OPT: #{client.owner}, user=#{data.user}, #{user}, opted=#{user.opted_in? ? 'in' : 'out'}"
      end
    end
  end
end
