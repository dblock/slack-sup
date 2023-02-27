module SlackSup
  module Commands
    class GCal < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackSup::Commands::Mixins::Subscribe

      subscribe_command 'gcal' do |data|
        raise SlackSup::Error, 'Missing GOOGLE_API_CLIENT_ID.' unless ENV['GOOGLE_API_CLIENT_ID']

        sup = Sup.where(conversation_id: data.channel).desc(:_id).first
        raise SlackSup::Error, "Please `#{data.team.bot_name} cal date/time` inside a S'Up DM channel." unless sup

        Chronic.time_class = sup.channel.sup_tzone
        dt = Chronic.parse(data.match['expression']) if data.match['expression']
        raise SlackSup::Error, "Please specify a date/time, eg. `#{data.team.bot_name} cal tomorrow 5pm`." unless dt

        data.team.slack_client.chat_postMessage(channel: data.channel, text: "Click this link to create a gcal for #{dt.strftime('%A, %B %d, %Y')} at #{dt.strftime('%l:%M %P').strip}: #{sup.calendar_href(dt)}")
        logger.info "CALENDAR: #{data.team}, user=#{data.user}"
      end
    end
  end
end
