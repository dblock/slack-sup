module SlackSup
  module Commands
    class Set < SlackRubyBot::Commands::Base
      include SlackSup::Commands::Mixins::Subscribe

      class << self
        def set_api(client, team, data, user, v = nil)
          if user.is_admin? && v
            team.update_attributes!(api: v.to_b)
            message = [
              "Team data access via the API is now #{team.api_s}.",
              team.api_url
            ].compact.join("\n")
            client.say(channel: data.channel, text: message)
          elsif v
            client.say(channel: data.channel, text: "Team data access via the API is #{team.api_s}. Only a Slack team admin can change that, sorry.")
          else
            message = [
              "Team data access via the API is #{team.api_s}.",
              team.api_url
            ].compact.join("\n")
            client.say(channel: data.channel, text: message)
          end
          logger.info "SET: #{team}, user=#{user.user_name}, api=#{team.api_s}"
        end

        def set_day(client, team, data, user, v = nil)
          if user.is_admin? && v
            team.update_attributes(sup_wday: Date.parse(v).wday)
            client.say(channel: data.channel, text: "Team S'Up is now on #{team.sup_day}.")
          elsif v
            client.say(channel: data.channel, text: "Team S'Up is on #{team.sup_day}. Only a Slack team admin can change that, sorry.")
          else
            client.say(channel: data.channel, text: "Team S'Up is on #{team.sup_day}.")
          end
          logger.info "SET: #{team}, user=#{user.user_name}, sup_day=#{team.sup_day}."
        rescue ArgumentError
          raise SlackSup::Error, "Day _#{v}_ is invalid, try _Monday_, _Tuesday_, etc. Team S'Up is on #{team.sup_day}."
        end

        def set_time(client, team, data, user, v = nil)
          if user.is_admin? && v
            team.update_attributes!(sup_time_of_day: DateTime.parse(v).seconds_since_midnight)
            client.say(channel: data.channel, text: "Team S'Up is now after #{team.sup_time_of_day_s}.")
          elsif v
            client.say(channel: data.channel, text: "Team S'Up is after #{team.sup_time_of_day_s}. Only a Slack team admin can change that, sorry.")
          else
            client.say(channel: data.channel, text: "Team S'Up is after #{team.sup_time_of_day_s}.")
          end
          logger.info "SET: #{team}, user=#{user.user_name}, sup_time_of_day=#{team.sup_time_of_day_s}."
        rescue StandardError => e
          raise SlackSup::Error, "Time _#{v}_ is invalid. Team S'Up is after #{team.reload.sup_time_of_day_s}."
        end

        def set_weeks(client, team, data, user, v = nil)
          if user.is_admin? && v
            team.update_attributes!(sup_every_n_weeks: v.to_i)
            client.say(channel: data.channel, text: "Team S'Up is now every #{team.sup_every_n_weeks_s}.")
          elsif v
            client.say(channel: data.channel, text: "Team S'Up is every #{team.sup_every_n_weeks_s}. Only a Slack team admin can change that, sorry.")
          else
            client.say(channel: data.channel, text: "Team S'Up is every #{team.sup_every_n_weeks_s}.")
          end
          logger.info "SET: #{team}, user=#{user.user_name}, sup_every_n_weeks=#{team.sup_every_n_weeks_s}."
        rescue StandardError => e
          raise SlackSup::Error, "Number _#{v}_ is invalid. Team S'Up is every #{team.reload.sup_every_n_weeks_s}."
        end

        def set_size(client, team, data, user, v = nil)
          if user.is_admin? && v
            team.update_attributes!(sup_size: v.to_i)
            client.say(channel: data.channel, text: "Team S'Up now connects #{team.sup_size} people.")
          elsif v
            client.say(channel: data.channel, text: "Team S'Up connects #{team.sup_size} people. Only a Slack team admin can change that, sorry.")
          else
            client.say(channel: data.channel, text: "Team S'Up connects #{team.sup_size} people.")
          end
          logger.info "SET: #{team}, user=#{user.user_name}, sup_size=#{team.sup_size}."
        rescue StandardError => e
          raise SlackSup::Error, "Number _#{v}_ is invalid. Team S'Up connects #{team.reload.sup_size} people."
        end

        def set_timezone(client, team, data, user, v = nil)
          if user.is_admin? && v
            timezone = ActiveSupport::TimeZone.new(v)
            raise SlackSup::Error, "TimeZone _#{v}_ is invalid, see https://github.com/rails/rails/blob/5.1.3/activesupport/lib/active_support/values/time_zone.rb#L30 for a list. Team S'Up timezone is currently #{team.sup_tzone}." unless timezone
            team.update_attributes!(sup_tz: timezone.name)
            client.say(channel: data.channel, text: "Team S'Up timezone is now #{team.sup_tzone}.")
          elsif v
            client.say(channel: data.channel, text: "Team S'Up timezone is #{team.sup_tzone}. Only a Slack team admin can change that, sorry.")
          else
            client.say(channel: data.channel, text: "Team S'Up timezone is #{team.sup_tzone}.")
          end
          logger.info "SET: #{team} user=#{user.user_name}, timezone=#{team.sup_tzone}."
        end

        def set_custom_profile_team_field(client, team, data, user, v = nil)
          if user.is_admin? && v
            team.update_attributes!(team_field_label: v)
            client.say(channel: data.channel, text: "Custom profile team field is now _#{team.team_field_label}_.")
          elsif v
            client.say(channel: data.channel, text: "Custom profile team field is _#{team.team_field_label || 'not set'}_. Only a Slack team admin can change that, sorry.")
          else
            client.say(channel: data.channel, text: "Custom profile team field is _#{team.team_field_label || 'not set'}_.")
          end
          logger.info "SET: #{team}, user=#{user.user_name}, team_field_label=#{team.team_field_label || '(not set)'}."
        end

        def unset_custom_profile_team_field(client, team, data, user)
          if user.is_admin?
            team.update_attributes!(team_field_label: nil)
            client.say(channel: data.channel, text: 'Custom profile team field is now _not set_.')
          else
            client.say(channel: data.channel, text: "Custom profile team field is _#{team.team_field_label || 'not set'}_. Only a Slack team admin can change that, sorry.")
          end
          logger.info "UNSET: #{team}, user=#{user.user_name}, team_field_label=#{team.team_field_label || '(not set)'}."
        end

        def set_message(client, team, data, user, v = nil)
          if user.is_admin? && v
            team.update_attributes!(sup_message: v.to_s)
            client.say(channel: data.channel, text: "Now using a custom S'Up message. _#{team.sup_message}_")
          elsif v && team.sup_message
            client.say(channel: data.channel, text: "Using a custom S'Up message. _#{team.sup_message}_ Only a Slack team admin can change that, sorry.")
          elsif v && !team.sup_message
            client.say(channel: data.channel, text: "Using the default S'Up message. _#{Sup::PLEASE_SUP_MESSAGE}_ Only a Slack team admin can change that, sorry.")
          elsif team.sup_message
            client.say(channel: data.channel, text: "Using a custom S'Up message. _#{team.sup_message}_")
          else
            client.say(channel: data.channel, text: "Using the default S'Up message. _#{Sup::PLEASE_SUP_MESSAGE}_")
          end
          logger.info "SET: #{team}, user=#{user.user_name}, sup_message=#{team.sup_message || '(not set)'}."
        end

        def unset_message(client, team, data, user)
          if user.is_admin?
            team.update_attributes!(sup_message: nil)
            client.say(channel: data.channel, text: "Now using the default S'Up message. _#{Sup::PLEASE_SUP_MESSAGE}_")
          elsif team.sup_message
            client.say(channel: data.channel, text: "Using a custom S'Up message. _#{team.sup_message}_ Only a Slack team admin can change that, sorry.")
          else
            client.say(channel: data.channel, text: "Using the default S'Up message. _#{Sup::PLEASE_SUP_MESSAGE}_ Only a Slack team admin can change that, sorry.")
          end
          logger.info "UNSET: #{team}, user=#{user.user_name}, sup_message=#{team.sup_message || '(not set)'}."
        end

        def set_recency(client, team, data, user, v = nil)
          if user.is_admin? && v
            team.update_attributes!(sup_recency: v.to_i)
            client.say(channel: data.channel, text: "Now taking special care to not pair the same people more than every #{team.sup_recency_s}.")
          elsif v
            client.say(channel: data.channel, text: "Taking special care to not pair the same people more than every #{team.sup_recency_s}. Only a Slack team admin can change that, sorry.")
          else
            client.say(channel: data.channel, text: "Taking special care to not pair the same people more than every #{team.sup_recency_s}.")
          end
          logger.info "SET: #{team}, user=#{user.user_name}, sup_recency=#{team.sup_recency_s}."
        rescue StandardError => e
          raise SlackSup::Error, "Number _#{v}_ is invalid. Taking special care to not pair the same people more than every #{team.reload.sup_recency_s}."
        end

        def set(client, team, data, user, k, v)
          case k
          when 'api' then
            set_api client, team, data, user, v
          when 'day' then
            set_day client, team, data, user, v
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
          when 'message' then
            set_message client, team, data, user, v
          else
            raise SlackSup::Error, "Invalid setting _#{k}_, see _help_ for available options."
          end
        end

        def unset(client, team, data, user, k)
          case k
          when 'teamfield' then
            unset_custom_profile_team_field client, team, data, user
          when 'message' then
            unset_message client, team, data, user
          else
            raise SlackSup::Error, "Invalid setting _#{k}_, see _help_ for available options."
          end
        end

        def parse_expression(m)
          m['expression']
            .gsub(/^team field/, 'teamfield')
            .split(/[\s]+/, 2)
        end
      end

      command 'set' do |client, data, match|
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        if !match['expression']
          team = client.owner
          message = [
            "Team S'Up connects #{team.sup_size} people on #{team.sup_day} after #{team.sup_time_of_day_s} every #{team.sup_every_n_weeks_s} in #{team.sup_tzone}, taking special care to not pair the same people more frequently than every #{team.sup_recency_s}.",
            "Custom profile team field is _#{team.team_field_label || 'not set'}_.",
            "Team data access via the API is #{team.api_s}.",
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
    end
  end
end
