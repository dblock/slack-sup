module SlackSup
  module Commands
    class Stats < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackSup::Commands::Mixins::Channel

      channel_command 'stats' do |channel, data|
        stats = channel ? ChannelStats.new(channel) : TeamStats.new(data.team)
        data.team.slack_client.chat_postMessage(channel: data.channel, text: stats.to_s)
        logger.info "STATS: #{data.team}, channel=#{data.channel}, user=#{data.user}"
      end
    end
  end
end
