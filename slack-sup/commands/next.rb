module SlackSup
  module Commands
    class Next < SlackRubyBot::Commands::Base
      include SlackSup::Commands::Mixins::Channel

      channel_command 'next' do |client, channel, data, _match|
        client.say(channel: data.channel, text: channel.next_sup_at_text)
        logger.info "NEXT: #{channel} - #{data.user}"
      end
    end
  end
end
