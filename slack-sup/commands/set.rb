module SlackSup
  module Commands
    class Set < SlackRubyBot::Commands::Base
      include SlackSup::Commands::Mixins::User

      class << self
        def set_opt_in(client, channel, data, user, v = nil)
          raise ArgumentError, "Invalid value: #{v}." unless ['in', 'out', nil].include?(v)

          if user.channel_admin? && v
            channel.update_attributes!(opt_in: v == 'in')
            client.say(channel: data.channel, text: "Users are now opted #{v} by default.")
          elsif v
            message = [
              "Users are opted #{channel.opt_in_s} by default.",
              "Only <@#{channel.inviter_id}> or a Slack team admin can change that, sorry."
            ].join(' ')
            client.say(channel: data.channel, text: message)
          else
            client.say(channel: data.channel, text: "Users are opted #{channel.opt_in_s} by default.")
          end
          logger.info "SET: #{channel}, user=#{user.user_name}, opt_in=#{channel.opt_in}"
        end

        def set_api(client, channel, data, user, v = nil)
          if user.channel_admin? && v
            channel.update_attributes!(api: v.to_b)
            message = [
              channel_data_access_message(user.reload, true),
              channel.api_url
            ].compact.join("\n")
            client.say(channel: data.channel, text: message)
          elsif v
            message = [
              channel_data_access_message(user),
              "Only <@#{channel.inviter_id}> or a Slack team admin can change that, sorry."
            ].join(' ')
            client.say(channel: data.channel, text: message)
          else
            message = [
              channel_data_access_message(user),
              channel.api_url
            ].compact.join("\n")
            client.say(channel: data.channel, text: message)
          end
          logger.info "SET: #{channel}, user=#{user.user_name}, api=#{channel.api_s}"
        end

        def set_api_token(client, channel, data, user)
          if !channel.api?
            set_api(client, channel, data, user)
          elsif user.channel_admin? && !channel.api_token
            channel.update_attributes!(api_token: SecureRandom.hex)
            message = [
              channel_data_access_message(user.reload, false, true),
              channel.api_url
            ].compact.join("\n")
            client.say(channel: data.channel, text: message)
          elsif user.channel_admin? && channel.api_token
            message = [
              channel_data_access_message(user),
              channel.api_url
            ].compact.join("\n")
            client.say(channel: data.channel, text: message)
          elsif !channel.api_token
            message = [
              channel_data_access_message(user),
              "Only <@#{channel.inviter_id}> or a Slack team admin can change that, sorry."
            ].join(' ')
            client.say(channel: data.channel, text: message)
          else
            message = [
              channel_data_access_message(user),
              channel.api_url
            ].join("\n")
            client.say(channel: data.channel, text: message)
          end
          logger.info "SET: #{channel}, user=#{user.user_name}, api=#{channel.api_s}, api_token=#{channel.api_token ? '(set)' : '(not set)'}"
        end

        def unset_api_token(client, channel, data, user)
          if !channel.api?
            set_api(client, channel, data, user)
          elsif user.channel_admin? && channel.api_token
            channel.update_attributes!(api_token: nil)
            message = [
              channel_data_access_message(user.reload, true),
              channel.api_url
            ].compact.join("\n")
            client.say(channel: data.channel, text: message)
          elsif user.channel_admin? && !channel.api_token
            message = [
              channel_data_access_message(user),
              channel.api_url
            ].compact.join("\n")
            client.say(channel: data.channel, text: message)
          else
            message = [
              channel_data_access_message(user),
              "Only <@#{channel.inviter_id}> or a Slack team admin can unset it, sorry."
            ].join(' ')
            client.say(channel: data.channel, text: message)
          end
          logger.info "UNSET: #{channel}, user=#{user.user_name}, api=#{channel.api_s}, api_token=#{channel.api_token ? '(set)' : '(not set)'}"
        end

        def rotate_api_token(client, channel, data, user)
          if !channel.api?
            set_api(client, channel, data, user)
          elsif user.channel_admin?
            channel.update_attributes!(api_token: SecureRandom.hex)
            message = [
              channel_data_access_message(user.reload, false, true),
              channel.api_url
            ].compact.join("\n")
            client.say(channel: data.channel, text: message)
          else
            message = [
              channel_data_access_message(user),
              "Only <@#{channel.inviter_id}> or a Slack team admin can rotate it, sorry."
            ].join(' ')
            client.say(channel: data.channel, text: message)
          end
          logger.info "SET: #{channel}, user=#{user.user_name}, api=#{channel.api_s}, api_token=(rotated)"
        end

        def team_set_api(client, team, data, user, v = nil)
          if team.is_admin?(user) && v
            team.update_attributes!(api: v.to_b)
            message = [
              team_data_access_message(team, user, true),
              team.api_url
            ].compact.join("\n")
            client.say(channel: data.channel, text: message)
          elsif v
            message = [
              team_data_access_message(team, user),
              "Only <@#{team.activated_user_id}> or a Slack team admin can change that, sorry."
            ].join(' ')
            client.say(channel: data.channel, text: message)
          else
            message = [
              team_data_access_message(team, user),
              team.api_url
            ].compact.join("\n")
            client.say(channel: data.channel, text: message)
          end
          logger.info "SET: #{team}, user=#{user}, api=#{team.api_s}"
        end

        def team_set_api_token(client, team, data, user)
          if !team.api?
            team_set_api(client, team, data, user)
          elsif team.is_admin?(user) && !team.api_token
            team.update_attributes!(api_token: SecureRandom.hex)
            message = [
              team_data_access_message(team, user, false, true),
              team.api_url
            ].compact.join("\n")
            client.say(channel: data.channel, text: message)
          elsif team.is_admin?(user) && team.api_token
            message = [
              team_data_access_message(team, user),
              team.api_url
            ].compact.join("\n")
            client.say(channel: data.channel, text: message)
          elsif !team.api_token
            message = [
              team_data_access_message(team, user),
              "Only <@#{team.activated_user_id}> or a Slack team admin can change that, sorry."
            ].join(' ')
            client.say(channel: data.channel, text: message)
          else
            message = [
              team_data_access_message(team, user),
              team.api_url
            ].join("\n")
            client.say(channel: data.channel, text: message)
          end
          logger.info "SET: #{team}, user=#{user}, api=#{team.api_s}, api_token=#{team.api_token ? '(set)' : '(not set)'}"
        end

        def team_unset_api_token(client, team, data, user)
          if !team.api?
            set_api(client, team, data, user)
          elsif team.is_admin?(user) && team.api_token
            team.update_attributes!(api_token: nil)
            message = [
              team_data_access_message(team, user, true),
              team.api_url
            ].compact.join("\n")
            client.say(channel: data.channel, text: message)
          elsif team.is_admin?(user) && !team.api_token
            message = [
              team_data_access_message(team, user),
              team.api_url
            ].compact.join("\n")
            client.say(channel: data.channel, text: message)
          else
            message = [
              team_data_access_message(team, user),
              "Only <@#{team.activated_user_id}> or a Slack team admin can unset it, sorry."
            ].join(' ')
            client.say(channel: data.channel, text: message)
          end
          logger.info "UNSET: #{team}, user=#{user}, api=#{team.api_s}, api_token=#{team.api_token ? '(set)' : '(not set)'}"
        end

        def team_rotate_api_token(client, team, data, user)
          if !team.api?
            set_api(client, team, data, user)
          elsif team.is_admin?(user)
            team.update_attributes!(api_token: SecureRandom.hex)
            message = [
              team_data_access_message(team, user, false, true),
              team.api_url
            ].compact.join("\n")
            client.say(channel: data.channel, text: message)
          else
            message = [
              team_data_access_message(team, user),
              "Only <@#{team.activated_user_id}> or a Slack team admin can rotate it, sorry."
            ].join(' ')
            client.say(channel: data.channel, text: message)
          end
          logger.info "SET: #{team}, user=#{user}, api=#{team.api_s}, api_token=(rotated)"
        end

        def set_day(client, channel, data, user, v = nil)
          if user.channel_admin? && v
            channel.update_attributes(sup_wday: Date.parse(v).wday)
            client.say(channel: data.channel, text: "Channel S'Up is now on #{channel.sup_day}.")
          elsif v
            client.say(channel: data.channel, text: "Channel S'Up is on #{channel.sup_day}. Only <@#{channel.inviter_id}> or a Slack team admin can change that, sorry.")
          else
            client.say(channel: data.channel, text: "Channel S'Up is on #{channel.sup_day}.")
          end
          logger.info "SET: #{channel}, user=#{user.user_name}, sup_day=#{channel.sup_day}."
        rescue ArgumentError
          raise SlackSup::Error, "Day _#{v}_ is invalid, try _Monday_, _Tuesday_, etc. Channel S'Up is on #{channel.sup_day}."
        end

        def set_time(client, channel, data, user, v = nil)
          if user.channel_admin? && v
            # attempt to parse a timezone right to left
            z = []
            tz = nil
            v.split(' ').reverse.each do |part|
              z << part
              tz = ActiveSupport::TimeZone.new(z.reverse.join(' '))
              break if tz
            end
            channel.update_attributes!(sup_tz: tz.name) if tz
            channel.update_attributes!(sup_time_of_day: DateTime.parse(v).seconds_since_midnight)
            client.say(channel: data.channel, text: "Channel S'Up is now after #{channel.sup_time_of_day_s} #{channel.sup_tzone_s}.")
          elsif v
            client.say(channel: data.channel, text: "Channel S'Up is after #{channel.sup_time_of_day_s} #{channel.sup_tzone_s}. Only <@#{channel.inviter_id}> or a Slack team admin can change that, sorry.")
          else
            client.say(channel: data.channel, text: "Channel S'Up is after #{channel.sup_time_of_day_s} #{channel.sup_tzone_s}.")
          end
          logger.info "SET: #{channel}, user=#{user.user_name}, sup_time_of_day=#{channel.sup_time_of_day_s}."
        rescue StandardError
          raise SlackSup::Error, "Time _#{v}_ is invalid. Channel S'Up is after #{channel.reload.sup_time_of_day_s} #{channel.sup_tzone_s}."
        end

        def set_followup_day(client, channel, data, user, v = nil)
          if user.channel_admin? && v
            channel.update_attributes(sup_followup_wday: Date.parse(v).wday)
            client.say(channel: data.channel, text: "Channel S'Up followup day is now on #{channel.sup_followup_day}.")
          elsif v
            client.say(channel: data.channel, text: "Channel S'Up followup day is on #{channel.sup_followup_day}. Only <@#{channel.inviter_id}> or a Slack team admin can change that, sorry.")
          else
            client.say(channel: data.channel, text: "Channel S'Up followup day is on #{channel.sup_followup_day}.")
          end
          logger.info "SET: #{channel}, user=#{user.user_name}, sup_followup_day=#{channel.sup_followup_day}."
        rescue ArgumentError
          raise SlackSup::Error, "Day _#{v}_ is invalid, try _Monday_, _Tuesday_, etc. Channel S'Up followup day is on #{channel.sup_followup_day}."
        end

        def set_weeks(client, channel, data, user, v = nil)
          if user.channel_admin? && v
            channel.update_attributes!(sup_every_n_weeks: v.to_i)
            client.say(channel: data.channel, text: "Channel S'Up is now every #{channel.sup_every_n_weeks_s}.")
          elsif v
            client.say(channel: data.channel, text: "Channel S'Up is every #{channel.sup_every_n_weeks_s}. Only <@#{channel.inviter_id}> or a Slack team admin can change that, sorry.")
          else
            client.say(channel: data.channel, text: "Channel S'Up is every #{channel.sup_every_n_weeks_s}.")
          end
          logger.info "SET: #{channel}, user=#{user.user_name}, sup_every_n_weeks=#{channel.sup_every_n_weeks_s}."
        rescue StandardError
          raise SlackSup::Error, "Number _#{v}_ is invalid. Channel S'Up is every #{channel.reload.sup_every_n_weeks_s}."
        end

        def set_size(client, channel, data, user, v = nil)
          if user.channel_admin? && v
            channel.update_attributes!(sup_size: v.to_i)
            client.say(channel: data.channel, text: "Channel S'Up now connects groups of #{channel.sup_size} people.")
          elsif v
            client.say(channel: data.channel, text: "Channel S'Up connects groups of #{channel.sup_size} people. Only <@#{channel.inviter_id}> or a Slack team admin can change that, sorry.")
          else
            client.say(channel: data.channel, text: "Channel S'Up connects groups of #{channel.sup_size} people.")
          end
          logger.info "SET: #{channel}, user=#{user.user_name}, sup_size=#{channel.sup_size}."
        rescue StandardError
          raise SlackSup::Error, "Number _#{v}_ is invalid. Channel S'Up connects groups of #{channel.reload.sup_size} people."
        end

        def set_odd(client, channel, data, user, v = nil)
          if user.channel_admin? && !v.nil?
            channel.update_attributes!(sup_odd: v.to_b)
            client.say(channel: data.channel, text: "Channel S'Up now connects groups of #{channel.sup_odd ? 'max ' : ''}#{channel.sup_size} people.")
          elsif !v.nil?
            client.say(channel: data.channel, text: "Channel S'Up connects groups of #{channel.sup_odd ? 'max ' : ''}#{channel.sup_size} people. Only <@#{channel.inviter_id}> or a Slack team admin can change that, sorry.")
          else
            client.say(channel: data.channel, text: "Channel S'Up connects groups of #{channel.sup_odd ? 'max ' : ''}#{channel.sup_size} people.")
          end
          logger.info "SET: #{channel}, user=#{user.user_name}, sup_odd=#{channel.sup_odd}."
        end

        def set_timezone(client, channel, data, user, v = nil)
          if user.channel_admin? && v
            timezone = ActiveSupport::TimeZone.new(v)
            raise SlackSup::Error, "TimeZone _#{v}_ is invalid, see https://github.com/rails/rails/blob/v#{ActiveSupport.gem_version}/activesupport/lib/active_support/values/time_zone.rb#L30 for a list. Channel S'Up timezone is currently #{channel.sup_tzone}." unless timezone

            channel.update_attributes!(sup_tz: timezone.name)
            client.say(channel: data.channel, text: "Channel S'Up timezone is now #{channel.sup_tzone}.")
          elsif v
            client.say(channel: data.channel, text: "Channel S'Up timezone is #{channel.sup_tzone}. Only <@#{channel.inviter_id}> or a Slack team admin can change that, sorry.")
          else
            client.say(channel: data.channel, text: "Channel S'Up timezone is #{channel.sup_tzone}.")
          end
          logger.info "SET: #{channel} user=#{user.user_name}, timezone=#{channel.sup_tzone}."
        end

        def set_custom_profile_team_field(client, channel, data, user, v = nil)
          if user.channel_admin? && v
            channel.update_attributes!(team_field_label: v)
            client.say(channel: data.channel, text: "Custom profile team field is now _#{channel.team_field_label}_.")
          elsif v
            client.say(channel: data.channel, text: "Custom profile team field is _#{channel.team_field_label || 'not set'}_. Only <@#{channel.inviter_id}> or a Slack team admin can change that, sorry.")
          else
            client.say(channel: data.channel, text: "Custom profile team field is _#{channel.team_field_label || 'not set'}_.")
          end
          logger.info "SET: #{channel}, user=#{user.user_name}, team_field_label=#{channel.team_field_label || '(not set)'}."
        end

        def unset_custom_profile_team_field(client, channel, data, user)
          if user.channel_admin?
            channel.update_attributes!(team_field_label: nil)
            client.say(channel: data.channel, text: 'Custom profile team field is now _not set_.')
          else
            client.say(channel: data.channel, text: "Custom profile team field is _#{channel.team_field_label || 'not set'}_. Only <@#{channel.inviter_id}> or a Slack team admin can change that, sorry.")
          end
          logger.info "UNSET: #{channel}, user=#{user.user_name}, team_field_label=#{channel.team_field_label || '(not set)'}."
        end

        def set_message(client, channel, data, user, v = nil)
          if user.channel_admin? && v
            channel.update_attributes!(sup_message: v.to_s)
            client.say(channel: data.channel, text: "Now using a custom S'Up message. _#{channel.sup_message}_")
          elsif v && channel.sup_message
            client.say(channel: data.channel, text: "Using a custom S'Up message. _#{channel.sup_message}_ Only <@#{channel.inviter_id}> or a Slack team admin can change that, sorry.")
          elsif v && !channel.sup_message
            client.say(channel: data.channel, text: "Using the default S'Up message. _#{Sup::PLEASE_SUP_MESSAGE}_ Only <@#{channel.inviter_id}> or a Slack team admin can change that, sorry.")
          elsif channel.sup_message
            client.say(channel: data.channel, text: "Using a custom S'Up message. _#{channel.sup_message}_")
          else
            client.say(channel: data.channel, text: "Using the default S'Up message. _#{Sup::PLEASE_SUP_MESSAGE}_")
          end
          logger.info "SET: #{channel}, user=#{user.user_name}, sup_message=#{channel.sup_message || '(not set)'}."
        end

        def unset_message(client, channel, data, user)
          if user.channel_admin?
            channel.update_attributes!(sup_message: nil)
            client.say(channel: data.channel, text: "Now using the default S'Up message. _#{Sup::PLEASE_SUP_MESSAGE}_")
          elsif channel.sup_message
            client.say(channel: data.channel, text: "Using a custom S'Up message. _#{channel.sup_message}_ Only <@#{channel.inviter_id}> or a Slack team admin can change that, sorry.")
          else
            client.say(channel: data.channel, text: "Using the default S'Up message. _#{Sup::PLEASE_SUP_MESSAGE}_ Only <@#{channel.inviter_id}> or a Slack team admin can change that, sorry.")
          end
          logger.info "UNSET: #{channel}, user=#{user.user_name}, sup_message=#{channel.sup_message || '(not set)'}."
        end

        def set_recency(client, channel, data, user, v = nil)
          if user.channel_admin? && v
            channel.update_attributes!(sup_recency: v.to_i)
            client.say(channel: data.channel, text: "Now taking special care to not pair the same people more than every #{channel.sup_recency_s}.")
          elsif v
            client.say(channel: data.channel, text: "Taking special care to not pair the same people more than every #{channel.sup_recency_s}. Only <@#{channel.inviter_id}> or a Slack team admin can change that, sorry.")
          else
            client.say(channel: data.channel, text: "Taking special care to not pair the same people more than every #{channel.sup_recency_s}.")
          end
          logger.info "SET: #{channel}, user=#{user.user_name}, sup_recency=#{channel.sup_recency_s}."
        rescue StandardError
          raise SlackSup::Error, "Number _#{v}_ is invalid. Taking special care to not pair the same people more than every #{channel.reload.sup_recency_s}."
        end

        def set_sync(client, channel, data, user, v = nil)
          if user.channel_admin? && v
            case v
            when 'now' then
              channel.update_attributes!(sync: true)
            else
              raise SlackSup::Error, "The option _#{v}_ is invalid. Use `now` to schedule a user sync in the next hour."
            end
            client.say(channel: data.channel, text: "#{channel.last_sync_at_text} Come back and run `set sync` or `stats` in a bit.")
          elsif v
            client.say(channel: data.channel, text: "#{channel.last_sync_at_text} Only <@#{channel.inviter_id}> or a Slack team admin can manually sync, sorry.")
          else
            client.say(channel: data.channel, text: channel.last_sync_at_text)
          end
          logger.info "SET: #{channel}, user=#{user.user_name}, sync_users=#{channel.sync}, last_sync_at=#{channel.last_sync_at}."
        end

        def team_set(client, team, data, user, k, v)
          case k
          when 'api' then
            team_set_api client, team, data, user, v
          when 'apitoken' then
            team_set_api_token client, team, data, user
          else
            raise SlackSup::Error, "Invalid global setting _#{k}_, see _help_ for available options."
          end
        end

        def channel_set(client, channel, data, user, k, v)
          case k
          when 'opt' then
            set_opt_in client, channel, data, user, v
          when 'api' then
            set_api client, channel, data, user, v
          when 'apitoken' then
            set_api_token client, channel, data, user
          when 'day' then
            set_day client, channel, data, user, v
          when 'followup' then
            set_followup_day client, channel, data, user, v
          when 'tz', 'timezone' then
            set_timezone client, channel, data, user, v
          when 'teamfield' then
            set_custom_profile_team_field client, channel, data, user, v
          when 'weeks' then
            set_weeks client, channel, data, user, v
          when 'recency' then
            set_recency client, channel, data, user, v
          when 'time' then
            set_time client, channel, data, user, v
          when 'size' then
            set_size client, channel, data, user, v
          when 'odd' then
            set_odd client, channel, data, user, v
          when 'message' then
            set_message client, channel, data, user, v
          when 'sync' then
            set_sync client, channel, data, user, v
          else
            raise SlackSup::Error, "Invalid channel setting _#{k}_, see _help_ for available options."
          end
        end

        def channel_unset(client, channel, data, user, k)
          case k
          when 'teamfield' then
            unset_custom_profile_team_field client, channel, data, user
          when 'apitoken' then
            unset_api_token client, channel, data, user
          when 'message' then
            unset_message client, channel, data, user
          else
            raise SlackSup::Error, "Invalid channel setting _#{k}_, see _help_ for available options."
          end
        end

        def team_unset(client, team, data, user, k)
          case k
          when 'apitoken' then
            team_unset_api_token client, team, data, user
          else
            raise SlackSup::Error, "Invalid global setting _#{k}_, see _help_ for available options."
          end
        end

        def channel_rotate(client, channel, data, user, k)
          case k
          when 'apitoken' then
            rotate_api_token client, channel, data, user
          else
            raise SlackSup::Error, "Invalid channel setting _#{k}_, see _help_ for available options."
          end
        end

        def team_rotate(client, team, data, user, k)
          case k
          when 'apitoken' then
            team_rotate_api_token client, team, data, user
          else
            raise SlackSup::Error, "Invalid global setting _#{k}_, see _help_ for available options."
          end
        end

        def parse_expression(m)
          m['expression']
            .gsub(/^team field/, 'teamfield')
            .gsub(/^api token/, 'apitoken')
            .split(/[\s]+/, 2)
        end

        def channel_data_access_message(user, updated_api = false, updated_token = false)
          if user.channel.api? && user.channel_admin? && user.channel.api_token
            "Channel data access via the API is #{updated_api ? 'now ' : nil}on with a#{updated_token ? ' new' : 'n'} access token `#{user.channel.api_token}`."
          elsif user.channel.api? && !user.channel_admin? && user.channel.api_token
            "Channel data access via the API is #{updated_api ? 'now ' : nil}on with a#{updated_token ? ' new' : 'n'} access token visible to admins."
          else
            "Channel data access via the API is #{updated_api ? 'now ' : nil}#{user.channel.api_s}."
          end
        end

        def team_data_access_message(team, user_id, updated_api = false, updated_token = false)
          if team.api? && team.is_admin?(user_id) && team.api_token
            "Team data access via the API is #{updated_api ? 'now ' : nil}on with a#{updated_token ? ' new' : 'n'} access token `#{team.api_token}`."
          elsif team.api? && !team.is_admin?(user_id) && team.api_token
            "Team data access via the API is #{updated_api ? 'now ' : nil}on with a#{updated_token ? ' new' : 'n'} access token visible to admins."
          else
            "Team data access via the API is #{updated_api ? 'now ' : nil}#{team.api_s}."
          end
        end
      end

      user_command 'set' do |client, channel, user, data, match|
        if !match['expression']
          if channel && user
            message = [
              "Channel S'Up connects groups of #{channel.sup_odd ? 'max ' : ''}#{channel.sup_size} people on #{channel.sup_day} after #{channel.sup_time_of_day_s} every #{channel.sup_every_n_weeks_s} in #{channel.sup_tzone}, taking special care to not pair the same people more frequently than every #{channel.sup_recency_s}.",
              "Channel users are _opted #{channel.opt_in_s}_ by default.",
              "Custom profile team field is _#{channel.team_field_label || 'not set'}_.",
              channel_data_access_message(user),
              channel.api_url
            ].compact.join("\n")
            client.say(channel: data.channel, text: message)
            logger.info "SET: #{channel}, user=#{user.user_id}"
          elsif user
            team = client.owner
            message = [
              team.enabled_channels_text,
              team_data_access_message(team, user),
              team.api_url
            ].compact.join("\n")
            client.say(channel: data.channel, text: message)
            logger.info "SET: #{team}, channel=#{data.channel}, user=#{user}"
          else
            raise 'expected user'
          end
        else
          k, v = parse_expression(match)
          if channel && user
            channel_set client, channel, data, user, k, v
          elsif user
            team_set client, client.owner, data, user, k, v
          end
        end
      end

      user_command 'unset' do |client, channel, user, data, match|
        if !match['expression']
          client.say(channel: data.channel, text: 'Missing setting, see _help_ for available options.')
          logger.info "UNSET: #{channel} - #{user.user_name}, failed, missing setting"
        else
          k, = parse_expression(match)
          if channel && user
            channel_unset client, channel, data, user, k
          else
            team_unset client, client.owner, data, user, k
          end
        end
      end

      user_command 'rotate' do |client, channel, user, data, match|
        if !match['expression']
          client.say(channel: data.channel, text: 'Missing setting, see _help_ for available options.')
          logger.info "UNSET: #{channel} - #{user.user_name}, failed, missing setting"
        else
          k, = parse_expression(match)
          if channel && user
            channel_rotate client, channel, data, user, k
          elsif user
            team_rotate client, client.owner, data, user, k
          end
        end
      end
    end
  end
end
