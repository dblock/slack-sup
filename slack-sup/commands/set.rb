module SlackSup
  module Commands
    class Set < SlackRubyBot::Commands::Base
      include SlackSup::Commands::Mixins::Subscribe

      class << self
        def set_api(client, data, user, v)
          if user.is_admin? || v.nil?
            client.owner.update_attributes!(api: v.to_b) unless v.nil?
            message = [
              "API for team #{client.owner.name} is #{client.owner.api? ? 'on!' : 'off.'}",
              client.owner.api_url
            ].compact.join("\n")
            client.say(channel: data.channel, text: message)
          else
            client.say(channel: data.channel, text: 'Only a Slack team admin can do this, sorry.')
           end
          logger.info "SET: #{client.owner} - #{user.user_name} API is #{client.owner.api? ? 'on' : 'off'}"
        end

        def unset_api(client, data, user)
          if user.is_admin?
            client.owner.update_attributes!(api: false)
            client.say(channel: data.channel, text: "API for team #{client.owner.name} is off.")
            logger.info "UNSET: #{client.owner} - #{user.user_name} API is off"
          else
            client.say(channel: data.channel, text: 'Only a Slack team admin can do this, sorry.')
          end
        end

        def set(client, data, user, k, v)
          case k
          when 'api' then
            set_api client, data, user, v
          else
            raise SlackSup::Error, "Invalid setting #{k}, you can _set api on|off_."
          end
        end

        def unset(client, data, user, k)
          case k
          when 'api' then
            unset_api client, data, user
          else
            raise SlackSup::Error, "Invalid setting #{k}, you can _unset api_."
          end
        end
      end

      command 'set' do |client, data, match|
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        if !match['expression']
          client.say(channel: data.channel, text: 'Missing setting, eg. _set api off_.')
          logger.info "SET: #{client.owner} - #{user.user_name}, failed, missing setting"
        else
          k, v = match['expression'].split(/[\s]+/, 2)
          set client, data, user, k, v
        end
      end

      command 'unset' do |client, data, match|
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        if !match['expression']
          client.say(channel: data.channel, text: 'Missing setting, eg. _unset api_.')
          logger.info "UNSET: #{client.owner} - #{user.user_name}, failed, missing setting"
        else
          k, = match['expression'].split(/[\s]+/, 2)
          unset client, data, user, k
        end
      end
    end
  end
end
