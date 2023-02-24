module SlackSup
  module Commands
    class GCal < SlackRubyBot::Commands::Base
      include SlackSup::Commands::Mixins::Subscribe

      subscribe_command 'gcal' do |client, data, match|
        raise SlackSup::Error, 'Missing GOOGLE_API_CLIENT_ID.' unless ENV['GOOGLE_API_CLIENT_ID']

        sup = Sup.where(conversation_id: data.channel).desc(:_id).first
        raise SlackSup::Error, "Please `#{client.owner.bot_name} cal date/time` inside a S'Up DM channel." unless sup

        Chronic.time_class = sup.channel.sup_tzone
        dt = Chronic.parse(match['expression']) if match['expression']
        raise SlackSup::Error, "Please specify a date/time, eg. `#{client.owner.bot_name} cal tomorrow 5pm`." unless dt

        client.say(channel: data.channel, text: "Click this link to create a gcal for #{dt.strftime('%A, %B %d, %Y')} at #{dt.strftime('%l:%M %P').strip}: #{sup.calendar_href(dt)}")
        logger.info "CALENDAR: #{client.owner}, user=#{data.user}"
      end
    end
  end
end
