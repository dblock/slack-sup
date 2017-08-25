module SlackSup
  module Commands
    class Calendar < SlackRubyBot::Commands::Base
      include SlackSup::Commands::Mixins::Subscribe

      subscribe_command 'calendar', 'cal' do |client, data, match|
        raise SlackSup::Error, 'Missing GOOGLE_API_CLIENT_ID.' unless ENV['GOOGLE_API_CLIENT_ID']
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        sup = Sup.where(channel_id: data.channel).desc(:_id).first
        raise SlackSup::Error, "Please `#{client.owner.bot_name} cal date/time` inside a S'Up DM channel." unless sup
        Chronic.time_class = client.owner.sup_tzone
        dt = Chronic.parse(match['expression']) if match['expression']
        raise SlackSup::Error, "Please specify a date/time, eg. `#{client.owner.bot_name} cal tomorrow 5pm`." unless dt
        client.say(channel: data.channel, text: "Click this link to create a calendar item on #{dt.strftime('%A, %B %d, %Y')} at #{dt.strftime('%l:%M %P').strip}: #{sup.calendar_href(dt)}")
        logger.info "CALENDAR: #{client.owner}, user=#{data.user}, #{user}"
      end
    end
  end
end
