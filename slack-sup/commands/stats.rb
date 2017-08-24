module SlackSup
  module Commands
    class Stats < SlackRubyBot::Commands::Base
      include SlackSup::Commands::Mixins::Subscribe

      def self.pluralize(count, text)
        case count
        when 1
          text
        else
          text.pluralize
        end
      end

      subscribe_command 'stats' do |client, data, _match|
        team = client.owner
        stats = ::Stats.new(team)
        message =
          "Team S'Up connects #{team.sup_size} people on #{team.sup_day} after #{team.sup_time_of_day_s} every #{team.sup_every_n_weeks_s}.\n" \
          "Team S'Up started #{team.created_at.ago_in_words} with #{stats.users_count > 0 ? stats.users_opted_in_count * 100 / stats.users_count : 0}% of users opted in.\n" \
          "Facilitated #{pluralize(stats.sups_count, 'S\'Up')} " \
          "in #{pluralize(stats.rounds_count, 'round')} " \
          "for #{pluralize(stats.users_in_sups_count, 'user')} " \
          "with #{stats.sups_count > 0 ? stats.positive_outcomes_count * 100 / stats.sups_count : 0}% positive outcomes " \
          "from #{stats.sups_count > 0 ? stats.reported_outcomes_count * 100 / stats.sups_count : 0}% outcomes reported."
        client.say(channel: data.channel, text: message)
        logger.info "STATS: #{client.owner} - #{data.user}"
      end
    end
  end
end
