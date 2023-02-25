module SlackSup
  module Commands
    class Next < SlackRubyBot::Commands::Base
      include SlackSup::Commands::Mixins::Channel

      channel_command 'next' do |client, channel, data, _match|
        channels = channel ? [channel] : client.owner.channels.enabled.asc(:_id)
        client.say(channel: data.channel, text: channels.map(&:next_sup_at_text).join("\n"))
        logger.info "NEXT: #{data.channel} - #{data.user}"
      end
    end
  end
end
