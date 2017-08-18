module SlackSup
  module Commands
    class About < SlackRubyBot::Commands::Base
      def self.call(client, data, _match)
        client.say(channel: data.channel, text: SlackSup::INFO)
        logger.info "INFO: #{client.owner}, user=#{data.user}"
      end
    end
  end
end
