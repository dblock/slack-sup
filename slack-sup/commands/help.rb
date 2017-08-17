module SlackSup
  module Commands
    class Help < SlackRubyBot::Commands::Base
      HELP = <<~EOS.freeze
        ```
        I am your friendly Team Sup bot.

        User
        ----
        opt in|out          - opt in/out of S'Up

        General
        -------

        help                - get this helpful message
        subscription        - show team ubscription info
        ```
EOS
      def self.call(client, data, _match)
        client.say(channel: data.channel, text: [
          HELP,
          SlackSup::INFO,
          client.owner.reload.subscribed? ? nil : client.owner.subscribe_text
        ].compact.join("\n"))
        client.say(channel: data.channel)
        logger.info "HELP: #{client.owner}, user=#{data.user}"
      end
    end
  end
end
