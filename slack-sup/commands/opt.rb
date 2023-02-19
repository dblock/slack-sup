module SlackSup
  module Commands
    class Opt < SlackRubyBot::Commands::Base
      include SlackSup::Commands::Mixins::User

      user_command 'opt' do |client, channel, user, data, match|
        expression, mention = match['expression'].split(/[\s]+/, 2) if match['expression']
        if mention
          raise SlackSup::Error, "Sorry, only <@#{channel.inviter_id}> or a Slack team admin can opt users in and out." unless user.channel_admin?

          user = channel.find_user_by_slack_mention!(mention)
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
        logger.info "OPT: #{channel}, user=#{data.user}, #{user}, opted=#{user.opted_in? ? 'in' : 'out'}"
      end
    end
  end
end
