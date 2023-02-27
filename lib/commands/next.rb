module SlackSup
  module Commands
    class Next < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackSup::Commands::Mixins::Channel

      channel_command 'next' do |channel, data|
        channels = channel ? [channel] : data.team.channels.enabled.asc(:_id)
        data.team.slack_client.chat_postMessage(channel: data.channel, text: channels.map(&:next_sup_at_text).join("\n"))
        logger.info "NEXT: #{data.team}, channel=#{data.channel}, user=#{data.user}"
      end
    end
  end
end
