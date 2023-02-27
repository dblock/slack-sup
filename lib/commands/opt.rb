module SlackSup
  module Commands
    class Opt < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackSup::Commands::Mixins::User
      include SlackSup::Commands::Mixins::Pluralize

      user_command 'opt' do |channel, user, data|
        user_ids = []
        channel_ids = []
        op = nil

        parts = data.match['expression'].split(/[\s]+/) if data.match['expression']
        parts&.each do |part|
          if part == 'in' || part == 'out'
            op = part
          elsif parsed_user = User.parse_slack_mention(part)
            user_ids << parsed_user
          elsif parsed_channel = Channel.parse_slack_mention(part)
            channel_ids << parsed_channel
          else
            raise SlackSup::Error, "Sorry, I don't understand who or what #{part} is."
          end
        end

        if user_ids.any? && channel.nil?
          raise SlackSup::Error, "Sorry, only <@#{data.team.activated_user_id}> or a Slack team admin can opt users in or out." unless data.team.is_admin?(data.user)
        elsif channel && user && user_ids.any?
          raise SlackSup::Error, "Sorry, only <@#{channel.inviter_id}> or a Slack team admin can opt users in and out." unless user.channel_admin?
        elsif channel && user && channel_ids.any?
          raise SlackSup::Error, "Please DM @#{data.team.name} to opt users in and out of channels." unless user.channel_admin?
        end

        user_ids << data.user if user_ids.none?
        channel_ids = data.team.channels.enabled.asc(:_id).map(&:channel_id) if channel_ids.none?

        messages = []

        user_ids.each do |user_id|
          opted_in = []
          opted_out = []
          not_a_member = []
          updated = false

          myself = (user_id == data.user)

          channel_ids.each do |channel_id|
            channel = data.team.channels.where(channel_id: channel_id).first
            raise SlackSup::Error, "Sorry, I can't find an existing S'Up channel <##{channel_id}>." unless channel

            user = channel.users.where(user_id: user_id).first
            if user && op
              case op
              when 'in' then
                unless user.opted_in
                  updated = true
                  user.update_attributes!(opted_in: true)
                end
                opted_in << channel.slack_mention
              when 'out' then
                if user.opted_in
                  updated = true
                  user.update_attributes!(opted_in: false)
                end
                opted_out << channel.slack_mention
              end
            elsif user&.opted_in
              opted_in << channel.slack_mention
            elsif user && !user.opted_in
              opted_out << channel.slack_mention
            else
              not_a_member << channel.slack_mention
            end
          end

          messages << if opted_in.any? || opted_out.any? || not_a_member.any?
                        [
                          (myself ? 'You are' : "User <@#{user_id}> is").to_s,
                          [
                            opted_in.any? ? "#{updated ? 'now ' : nil}opted in to #{opted_in.and}" : nil,
                            opted_out.any? ? "#{updated ? 'now ' : nil}opted out of #{opted_out.and}" : nil,
                            not_a_member.any? ? "not a member of #{not_a_member.and}" : nil
                          ].compact.and
                        ].compact.join(' ') + '.'
                      else
                        "#{myself ? 'You were' : "User <@#{user_id}> was"} not found in any channels."
                      end
        end

        data.team.slack_client.chat_postMessage(channel: data.channel, text: messages.join("\n"))
        logger.info "OPT: #{data.team}, for=#{user}, channel=#{data.channel}, user=#{data.user}"
      end
    end
  end
end
