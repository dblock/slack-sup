module SlackSup
  module Commands
    class Set < SlackRubyBot::Commands::Base
      include SlackSup::Commands::Mixins::Subscribe

      class << self
        def set_opt_in(client, team, data, user, v = nil)
          raise ArgumentError, "Invalid value: #{v}." unless ['in', 'out', nil].include?(v)

          if user.team_admin? && v
            team.update_attributes!(opt_in: v == 'in')
            client.say(channel: data.channel, text: "Users are now opted #{v} by default.")
          elsif v
            message = [
              "Users are opted #{team.opt_in_s} by default.",
              "Only #{team.team_admins_slack_mentions} can change that, sorry."
            ].join(' ')
            client.say(channel: data.channel, text: message)
          else
            client.say(channel: data.channel, text: "Users are opted #{team.opt_in_s} by default.")
          end
          logger.info "SET: #{team}, user=#{user.user_name}, opt_in=#{team.opt_in}"
        end

        def set_api(client, team, data, user, v = nil)
          if user.team_admin? && v
            team.update_attributes!(api: v.to_b)
            message = [
              team_data_access_message(user.reload, true),
              team.api_url
            ].compact.join("\n")
            client.say(channel: data.channel, text: message)
          elsif v
            message = [
              team_data_access_message(user),
              "Only #{team.team_admins_slack_mentions} can change that, sorry."
            ].join(' ')
            client.say(channel: data.channel, text: message)
          else
            message = [
              team_data_access_message(user),
              team.api_url
            ].compact.join("\n")
            client.say(channel: data.channel, text: message)
          end
          logger.info "SET: #{team}, user=#{user.user_name}, api=#{team.api_s}"
        end

        def set_api_token(client, team, data, user)
          if !team.api?
            set_api(client, team, data, user)
          elsif user.team_admin? && !team.api_token
            team.update_attributes!(api_token: SecureRandom.hex)
            message = [
              team_data_access_message(user.reload, false, true),
              team.api_url
            ].compact.join("\n")
            client.say(channel: data.channel, text: message)
          elsif user.team_admin? && team.api_token
            message = [
              team_data_access_message(user),
              team.api_url
            ].compact.join("\n")
            client.say(channel: data.channel, text: message)
          elsif !team.api_token
            message = [
              team_data_access_message(user),
              "Only #{team.team_admins_slack_mentions} can change that, sorry."
            ].join(' ')
            client.say(channel: data.channel, text: message)
          else
            message = [
              team_data_access_message(user),
              team.api_url
            ].join("\n")
            client.say(channel: data.channel, text: message)
          end
          logger.info "SET: #{team}, user=#{user.user_name}, api=#{team.api_s}, api_token=#{team.api_token ? '(set)' : '(not set)'}"
        end

        def unset_api_token(client, team, data, user)
          if !team.api?
            set_api(client, team, data, user)
          elsif user.team_admin? && team.api_token
            team.update_attributes!(api_token: nil)
            message = [
              team_data_access_message(user.reload, true),
              team.api_url
            ].compact.join("\n")
            client.say(channel: data.channel, text: message)
          elsif user.team_admin? && !team.api_token
            message = [
              team_data_access_message(user),
              team.api_url
            ].compact.join("\n")
            client.say(channel: data.channel, text: message)
          else
            message = [
              team_data_access_message(user),
              "Only #{team.team_admins_slack_mentions} can unset it, sorry."
            ].join(' ')
            client.say(channel: data.channel, text: message)
          end
          logger.info "UNSET: #{team}, user=#{user.user_name}, api=#{team.api_s}, api_token=#{team.api_token ? '(set)' : '(not set)'}"
        end

        def rotate_api_token(client, team, data, user)
          if !team.api?
            set_api(client, team, data, user)
          elsif user.team_admin?
            team.update_attributes!(api_token: SecureRandom.hex)
            message = [
              team_data_access_message(user.reload, false, true),
              team.api_url
            ].compact.join("\n")
            client.say(channel: data.channel, text: message)
          else
            message = [
              team_data_access_message(user),
              "Only #{team.team_admins_slack_mentions} can rotate it, sorry."
            ].join(' ')
            client.say(channel: data.channel, text: message)
          end
          logger.info "SET: #{team}, user=#{user.user_name}, api=#{team.api_s}, api_token=(rotated)"
        end

        def set_day(client, team, data, user, v = nil)
          if user.team_admin? && v
            team.update_attributes(sup_wday: Date.parse(v).wday)
            client.say(channel: data.channel, text: "Team S'Up is now on #{team.sup_day}.")
          elsif v
            client.say(channel: data.channel, text: "Team S'Up is on #{team.sup_day}. Only #{team.team_admins_slack_mentions} can change that, sorry.")
          else
            client.say(channel: data.channel, text: "Team S'Up is on #{team.sup_day}.")
          end
          logger.info "SET: #{team}, user=#{user.user_name}, sup_day=#{team.sup_day}."
        rescue ArgumentError
          raise SlackSup::Error, "Day _#{v}_ is invalid, try _Monday_, _Tuesday_, etc. Team S'Up is on #{team.sup_day}."
        end

        def set_time(client, team, data, user, v = nil)
          if user.team_admin? && v
            # attempt to parse a timezone right to left
            z = []
            tz = nil
            v.split(' ').reverse.each do |part|
              z << part
              tz = ActiveSupport::TimeZone.new(z.reverse.join(' '))
              break if tz
            end
            team.update_attributes!(sup_tz: tz.name) if tz
            team.update_attributes!(sup_time_of_day: DateTime.parse(v).seconds_since_midnight)
            client.say(channel: data.channel, text: "Team S'Up is now after #{team.sup_time_of_day_s} #{team.sup_tzone_s}.")
          elsif v
            client.say(channel: data.channel, text: "Team S'Up is after #{team.sup_time_of_day_s} #{team.sup_tzone_s}. Only #{team.team_admins_slack_mentions} can change that, sorry.")
          else
            client.say(channel: data.channel, text: "Team S'Up is after #{team.sup_time_of_day_s} #{team.sup_tzone_s}.")
          end
          logger.info "SET: #{team}, user=#{user.user_name}, sup_time_of_day=#{team.sup_time_of_day_s}."
        rescue StandardError
          raise SlackSup::Error, "Time _#{v}_ is invalid. Team S'Up is after #{team.reload.sup_time_of_day_s} #{team.sup_tzone_s}."
        end

        def set_followup_day(client, team, data, user, v = nil)
          if user.team_admin? && v
            team.update_attributes(sup_followup_wday: Date.parse(v).wday)
            client.say(channel: data.channel, text: "Team S'Up followup day is now on #{team.sup_followup_day}.")
          elsif v
            client.say(channel: data.channel, text: "Team S'Up followup day is on #{team.sup_followup_day}. Only #{team.team_admins_slack_mentions} can change that, sorry.")
          else
            client.say(channel: data.channel, text: "Team S'Up followup day is on #{team.sup_followup_day}.")
          end
          logger.info "SET: #{team}, user=#{user.user_name}, sup_followup_day=#{team.sup_followup_day}."
        rescue ArgumentError
          raise SlackSup::Error, "Day _#{v}_ is invalid, try _Monday_, _Tuesday_, etc. Team S'Up followup day is on #{team.sup_followup_day}."
        end

        def set_weeks(client, team, data, user, v = nil)
          if user.team_admin? && v
            team.update_attributes!(sup_every_n_weeks: v.to_i)
            client.say(channel: data.channel, text: "Team S'Up is now every #{team.sup_every_n_weeks_s}.")
          elsif v
            client.say(channel: data.channel, text: "Team S'Up is every #{team.sup_every_n_weeks_s}. Only #{team.team_admins_slack_mentions} can change that, sorry.")
          else
            client.say(channel: data.channel, text: "Team S'Up is every #{team.sup_every_n_weeks_s}.")
          end
          logger.info "SET: #{team}, user=#{user.user_name}, sup_every_n_weeks=#{team.sup_every_n_weeks_s}."
        rescue StandardError
          raise SlackSup::Error, "Number _#{v}_ is invalid. Team S'Up is every #{team.reload.sup_every_n_weeks_s}."
        end

        def set_size(client, team, data, user, v = nil)
          if user.team_admin? && v
            team.update_attributes!(sup_size: v.to_i)
            client.say(channel: data.channel, text: "Team S'Up now connects groups of #{team.sup_size} people.")
          elsif v
            client.say(channel: data.channel, text: "Team S'Up connects groups of #{team.sup_size} people. Only #{team.team_admins_slack_mentions} can change that, sorry.")
          else
            client.say(channel: data.channel, text: "Team S'Up connects groups of #{team.sup_size} people.")
          end
          logger.info "SET: #{team}, user=#{user.user_name}, sup_size=#{team.sup_size}."
        rescue StandardError
          raise SlackSup::Error, "Number _#{v}_ is invalid. Team S'Up connects groups of #{team.reload.sup_size} people."
        end

        def set_odd(client, team, data, user, v = nil)
          if user.team_admin? && !v.nil?
            team.update_attributes!(sup_odd: v.to_b)
            client.say(channel: data.channel, text: "Team S'Up now connects groups of #{team.sup_odd ? 'max ' : ''}#{team.sup_size} people.")
          elsif !v.nil?
            client.say(channel: data.channel, text: "Team S'Up connects groups of #{team.sup_odd ? 'max ' : ''}#{team.sup_size} people. Only #{team.team_admins_slack_mentions} can change that, sorry.")
          else
            client.say(channel: data.channel, text: "Team S'Up connects groups of #{team.sup_odd ? 'max ' : ''}#{team.sup_size} people.")
          end
          logger.info "SET: #{team}, user=#{user.user_name}, sup_odd=#{team.sup_odd}."
        end

        def set_timezone(client, team, data, user, v = nil)
          if user.team_admin? && v
            timezone = ActiveSupport::TimeZone.new(v)
            raise SlackSup::Error, "TimeZone _#{v}_ is invalid, see https://github.com/rails/rails/blob/v#{ActiveSupport.gem_version}/activesupport/lib/active_support/values/time_zone.rb#L30 for a list. Team S'Up timezone is currently #{team.sup_tzone}." unless timezone

            team.update_attributes!(sup_tz: timezone.name)
            client.say(channel: data.channel, text: "Team S'Up timezone is now #{team.sup_tzone}.")
          elsif v
            client.say(channel: data.channel, text: "Team S'Up timezone is #{team.sup_tzone}. Only #{team.team_admins_slack_mentions} can change that, sorry.")
          else
            client.say(channel: data.channel, text: "Team S'Up timezone is #{team.sup_tzone}.")
          end
          logger.info "SET: #{team} user=#{user.user_name}, timezone=#{team.sup_tzone}."
        end

        def set_custom_profile_team_field(client, team, data, user, v = nil)
          if user.team_admin? && v
            team.update_attributes!(team_field_label: v)
            client.say(channel: data.channel, text: "Custom profile team field is now _#{team.team_field_label}_.")
          elsif v
            client.say(channel: data.channel, text: "Custom profile team field is _#{team.team_field_label || 'not set'}_. Only #{team.team_admins_slack_mentions} can change that, sorry.")
          else
            client.say(channel: data.channel, text: "Custom profile team field is _#{team.team_field_label || 'not set'}_.")
          end
          logger.info "SET: #{team}, user=#{user.user_name}, team_field_label=#{team.team_field_label || '(not set)'}."
        end

        def unset_custom_profile_team_field(client, team, data, user)
          if user.team_admin?
            team.update_attributes!(team_field_label: nil)
            client.say(channel: data.channel, text: 'Custom profile team field is now _not set_.')
          else
            client.say(channel: data.channel, text: "Custom profile team field is _#{team.team_field_label || 'not set'}_. Only #{team.team_admins_slack_mentions} can change that, sorry.")
          end
          logger.info "UNSET: #{team}, user=#{user.user_name}, team_field_label=#{team.team_field_label || '(not set)'}."
        end

        def set_message(client, team, data, user, v = nil)
          if user.team_admin? && v
            team.update_attributes!(sup_message: v.to_s)
            client.say(channel: data.channel, text: "Now using a custom S'Up message. _#{team.sup_message}_")
          elsif v && team.sup_message
            client.say(channel: data.channel, text: "Using a custom S'Up message. _#{team.sup_message}_ Only #{team.team_admins_slack_mentions} can change that, sorry.")
          elsif v && !team.sup_message
            client.say(channel: data.channel, text: "Using the default S'Up message. _#{Sup::PLEASE_SUP_MESSAGE}_ Only #{team.team_admins_slack_mentions} can change that, sorry.")
          elsif team.sup_message
            client.say(channel: data.channel, text: "Using a custom S'Up message. _#{team.sup_message}_")
          else
            client.say(channel: data.channel, text: "Using the default S'Up message. _#{Sup::PLEASE_SUP_MESSAGE}_")
          end
          logger.info "SET: #{team}, user=#{user.user_name}, sup_message=#{team.sup_message || '(not set)'}."
        end

        def unset_message(client, team, data, user)
          if user.team_admin?
            team.update_attributes!(sup_message: nil)
            client.say(channel: data.channel, text: "Now using the default S'Up message. _#{Sup::PLEASE_SUP_MESSAGE}_")
          elsif team.sup_message
            client.say(channel: data.channel, text: "Using a custom S'Up message. _#{team.sup_message}_ Only #{team.team_admins_slack_mentions} can change that, sorry.")
          else
            client.say(channel: data.channel, text: "Using the default S'Up message. _#{Sup::PLEASE_SUP_MESSAGE}_ Only #{team.team_admins_slack_mentions} can change that, sorry.")
          end
          logger.info "UNSET: #{team}, user=#{user.user_name}, sup_message=#{team.sup_message || '(not set)'}."
        end

        def set_recency(client, team, data, user, v = nil)
          if user.team_admin? && v
            team.update_attributes!(sup_recency: v.to_i)
            client.say(channel: data.channel, text: "Now taking special care to not pair the same people more than every #{team.sup_recency_s}.")
          elsif v
            client.say(channel: data.channel, text: "Taking special care to not pair the same people more than every #{team.sup_recency_s}. Only #{team.team_admins_slack_mentions} can change that, sorry.")
          else
            client.say(channel: data.channel, text: "Taking special care to not pair the same people more than every #{team.sup_recency_s}.")
          end
          logger.info "SET: #{team}, user=#{user.user_name}, sup_recency=#{team.sup_recency_s}."
        rescue StandardError
          raise SlackSup::Error, "Number _#{v}_ is invalid. Taking special care to not pair the same people more than every #{team.reload.sup_recency_s}."
        end

        def set_sync(client, team, data, user, v = nil)
          if user.team_admin? && v
            case v
            when 'now' then
              team.update_attributes!(sync: true)
            else
              raise SlackSup::Error, "The option _#{v}_ is invalid. Use `now` to schedule a user sync in the next hour."
            end
            client.say(channel: data.channel, text: "#{team.last_sync_at_text} Come back and run `set sync` or `stats` in a bit.")
          elsif v
            client.say(channel: data.channel, text: "#{team.last_sync_at_text} Only #{team.team_admins_slack_mentions} can manually sync, sorry.")
          else
            client.say(channel: data.channel, text: team.last_sync_at_text)
          end
          logger.info "SET: #{team}, user=#{user.user_name}, sync_users=#{team.sync}, last_sync_at=#{team.last_sync_at}."
        end

        def set(client, team, data, user, k, v)
          case k
          when 'opt' then
            set_opt_in client, team, data, user, v
          when 'api' then
            set_api client, team, data, user, v
          when 'apitoken' then
            set_api_token client, team, data, user
          when 'day' then
            set_day client, team, data, user, v
          when 'followup' then
            set_followup_day client, team, data, user, v
          when 'tz', 'timezone' then
            set_timezone client, team, data, user, v
          when 'teamfield' then
            set_custom_profile_team_field client, team, data, user, v
          when 'weeks' then
            set_weeks client, team, data, user, v
          when 'recency' then
            set_recency client, team, data, user, v
          when 'time' then
            set_time client, team, data, user, v
          when 'size' then
            set_size client, team, data, user, v
          when 'odd' then
            set_odd client, team, data, user, v
          when 'message' then
            set_message client, team, data, user, v
          when 'sync' then
            set_sync client, team, data, user, v
          else
            raise SlackSup::Error, "Invalid setting _#{k}_, see _help_ for available options."
          end
        end

        def unset(client, team, data, user, k)
          case k
          when 'teamfield' then
            unset_custom_profile_team_field client, team, data, user
          when 'apitoken' then
            unset_api_token client, team, data, user
          when 'message' then
            unset_message client, team, data, user
          else
            raise SlackSup::Error, "Invalid setting _#{k}_, see _help_ for available options."
          end
        end

        def rotate(client, team, data, user, k)
          case k
          when 'apitoken' then
            rotate_api_token client, team, data, user
          else
            raise SlackSup::Error, "Invalid setting _#{k}_, see _help_ for available options."
          end
        end

        def parse_expression(m)
          m['expression']
            .gsub(/^team field/, 'teamfield')
            .gsub(/^api token/, 'apitoken')
            .split(/[\s]+/, 2)
        end

        def team_data_access_message(user, updated_api = false, updated_token = false)
          if user.team.api? && user.team_admin? && user.team.api_token
            "Team data access via the API is #{updated_api ? 'now ' : nil}on with a#{updated_token ? ' new' : 'n'} access token `#{user.team.api_token}`."
          elsif user.team.api? && !user.team_admin? && user.team.api_token
            "Team data access via the API is #{updated_api ? 'now ' : nil}on with a#{updated_token ? ' new' : 'n'} access token visible to admins."
          else
            "Team data access via the API is #{updated_api ? 'now ' : nil}#{user.team.api_s}."
          end
        end
      end

      command 'set' do |client, data, match|
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        if !match['expression']
          team = client.owner
          message = [
            "Team S'Up connects groups of #{team.sup_odd ? 'max ' : ''}#{team.sup_size} people on #{team.sup_day} after #{team.sup_time_of_day_s} every #{team.sup_every_n_weeks_s} in #{team.sup_tzone}, taking special care to not pair the same people more frequently than every #{team.sup_recency_s}.",
            "Users are _opted #{team.opt_in_s}_ by default.",
            "Custom profile team field is _#{team.team_field_label || 'not set'}_.",
            team_data_access_message(user),
            team.api_url
          ].compact.join("\n")
          client.say(channel: data.channel, text: message)
          logger.info "SET: #{client.owner} - #{user.user_name}"
        else
          k, v = parse_expression(match)
          set client, client.owner, data, user, k, v
        end
      end

      command 'unset' do |client, data, match|
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        if !match['expression']
          client.say(channel: data.channel, text: 'Missing setting, see _help_ for available options.')
          logger.info "UNSET: #{client.owner} - #{user.user_name}, failed, missing setting"
        else
          k, = parse_expression(match)
          unset client, client.owner, data, user, k
        end
      end

      command 'rotate' do |client, data, match|
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        if !match['expression']
          client.say(channel: data.channel, text: 'Missing setting, see _help_ for available options.')
          logger.info "UNSET: #{client.owner} - #{user.user_name}, failed, missing setting"
        else
          k, = parse_expression(match)
          rotate client, client.owner, data, user, k
        end
      end
    end
  end
end
