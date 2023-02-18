module SlackSup
  module Commands
    class Next < SlackRubyBot::Commands::Base
      include SlackSup::Commands::Mixins::Subscribe

      subscribe_command 'next' do |client, data, _match|
        team = client.owner
        client.say(channel: data.channel, text: team.next_sup_at_text)
        logger.info "NEXT: #{client.owner} - #{data.user}"
      end
    end
  end
end
