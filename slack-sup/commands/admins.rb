module SlackSup
  module Commands
    class Admins < SlackRubyBot::Commands::Base
      def self.call(client, data, _match)
        admins = client.owner.team_admins_slack_mentions
        client.say(channel: data.channel, text: "Team #{admins.count == 1 ? 'admin is' : 'admins are'} #{admins.and}.")
        logger.info "ADMINS: #{client.owner}, user=#{data.user}"
      end
    end
  end
end
