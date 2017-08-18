module SlackSup
  module Commands
    class Help < SlackRubyBot::Commands::Base
      HELP = <<~EOS.freeze
        ```
        Hi there! I'm your team's S'Up bot.

        The most valuable relationships are not made of two people, they’re made of three.

        User
        ----
        opt in|out             - opt in/out of S'Up

        General
        -------
        help                   - this helpful message
        about                  - more helpful info about this bot

        Team Admins
        -----------
        set day [day of week]  - set the day to S'Up, default is Monday
        set api on|off         - enable/disable API access to your team data
        subscription           - show team ubscription info

        More information at https://sup.playplay.io
        ```
EOS
      def self.call(client, data, _match)
        client.say(channel: data.channel, text: [
          HELP,
          client.owner.reload.subscribed? ? nil : client.owner.subscribe_text
        ].compact.join("\n"))
        logger.info "HELP: #{client.owner}, user=#{data.user}"
      end
    end
  end
end
