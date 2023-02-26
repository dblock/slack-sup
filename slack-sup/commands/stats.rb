module SlackSup
  module Commands
    class Stats < SlackRubyBot::Commands::Base
      include SlackSup::Commands::Mixins::Channel

      channel_command 'stats' do |client, channel, data, _match|
        stats = channel ? ChannelStats.new(channel) : TeamStats.new(client.owner)
        client.say(channel: data.channel, text: stats.to_s)
        logger.info "STATS: #{client.owner}, channel=#{data.channel}, user=#{data.user}"
      end
    end
  end
end
