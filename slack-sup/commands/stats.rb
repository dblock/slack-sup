module SlackSup
  module Commands
    class Stats < SlackRubyBot::Commands::Base
      include SlackSup::Commands::Mixins::Subscribe

      def self.pluralize(count, text)
        case count
        when 1
          "#{count} #{text}"
        else
          "#{count} #{text.pluralize}"
        end
      end

      subscribe_command 'stats' do |client, data, _match|
        team = client.owner
        stats = ::Stats.new(team)
        messages = []
        messages << "Team S'Up connects groups of #{team.sup_size} people on #{team.sup_day} after #{team.sup_time_of_day_s} every #{team.sup_every_n_weeks_s}."
        messages << if stats.users_count > 0 && stats.users_opted_in_count > 0
                      "Team S'Up started #{team.created_at.ago_in_words} with #{stats.users_opted_in_count * 100 / stats.users_count}% (#{stats.users_opted_in_count}/#{stats.users_count}) of users opted in."
                    else
                      "Team S'Up started #{team.created_at.ago_in_words} with no users (0/#{stats.users_count}) opted in."
                    end
        if stats.sups_count > 0
          messages << "Facilitated #{pluralize(stats.sups_count, 'S\'Up')} " \
            "in #{pluralize(stats.rounds_count, 'round')} " \
            "for #{pluralize(stats.users_in_sups_count, 'user')} " \
            "with #{stats.positive_outcomes_count * 100 / stats.sups_count}% positive outcomes " \
            "from #{stats.reported_outcomes_count * 100 / stats.sups_count}% outcomes reported."
        end
        client.say(channel: data.channel, text: messages.join("\n"))
        logger.info "STATS: #{client.owner} - #{data.user}"
      end
    end
  end
end
