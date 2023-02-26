module SlackSup
  module Commands
    class Opt < SlackRubyBot::Commands::Base
      include SlackSup::Commands::Mixins::User
      include SlackSup::Commands::Mixins::Pluralize

      user_command 'opt' do |client, channel, user, data, match|
        if channel && user
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
          logger.info "OPT: #{client.owner}, channel=#{data.channel}, #{user}, opted=#{user.opted_in? ? 'in' : 'out'}"
        else
          mention = match['expression']
          if mention
            raise SlackSup::Error, "Sorry, only <@#{client.owner.activated_user_id}> or a Slack team admin can see whether users are opted in or out." unless client.owner.is_admin?(data.user)

            user = User.parse_slack_mention!(mention)
          end

          opted_in = []
          opted_out = []
          not_a_member = []
          client.owner.channels.enabled.asc(:_id).each do |channel|
            known_user = channel.users.where(user_id: user).first
            if known_user && mention
              if known_user.opted_in
                opted_in << channel.slack_mention
              else
                opted_out << channel.slack_mention
              end
            elsif mention
              not_a_member << channel.slack_mention
            end
          end

          if opted_in.any? || opted_out.any? || not_a_member.any?
            client.say(channel: data.channel, text: [
              (mention ? "User <@#{user}> is" : 'You are').to_s,
              [
                opted_in.any? ? "opted in to #{opted_in.and}" : nil,
                opted_out.any? ? "opted out of #{opted_out.and}" : nil,
                not_a_member.any? ? "not a member of #{not_a_member.and}" : nil
              ].compact.and
            ].compact.join(' ') + '.')
          else
            client.say(channel: data.channel, text: "#{mention ? "User <@#{user}> was" : 'You were'} not found in any channels.")
          end

          logger.info "OPT: #{client.owner}, for=#{user}, channel=#{data.channel}, user=#{data.user}"
        end
      end
    end
  end
end
