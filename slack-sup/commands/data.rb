module SlackSup
  module Commands
    class Data < SlackRubyBot::Commands::Base
      include SlackSup::Commands::Mixins::Subscribe
      include SlackSup::Commands::Mixins::Pluralize

      def self.parse_number_of_rounds(m)
        return 1 unless m

        m.downcase == 'all' ? nil : Integer(m)
      end

      subscribe_command 'data' do |client, data, match|
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        raise SlackSup::Error, "Sorry, only #{user.team.team_admins_slack_mentions.or} can download data." unless user.team_admin?
        raise SlackSup::Error, "Hey <@#{data.user}>, we are still working on your previous request." if Export.where(team: client.owner, user_id: data.user, exported: false).exists?

        rounds = if match['expression']
                   parse_number_of_rounds(match['expression'])
                 else
                   1
                 end

        raise SlackSup::Error, "Sorry, #{rounds} is not a valid number of rounds." unless rounds.nil? || rounds&.positive?
        raise SlackSup::Error, "Sorry, I didn't find any rounds, try `all` to get all data." if rounds && rounds >= 0 && client.owner.rounds.empty?
        raise SlackSup::Error, "Sorry, I only found #{pluralize(client.owner.rounds.size, 'round')}, try 1, #{client.owner.rounds.size} or `all`." if rounds && client.owner.rounds.count < rounds

        Export.create!(
          team: client.owner,
          user_id: data.user,
          max_rounds_count: rounds
        )

        rounds_s = if rounds == 1
                     'the most recent round'
                   elsif rounds&.positive?
                     "#{rounds} most recent rounds"
                   else
                     'all rounds'
                   end

        client.say(channel: data.channel, text: "Hey #{user.slack_mention}, we will prepare your team data for #{rounds_s} in the next few minutes, please check your DMs for a link.")
        logger.info "DATA: #{data.team}, user=#{data.user}, rounds=#{rounds}"
      end
    end
  end
end
