module SlackSup
  module Commands
    class Rounds < SlackRubyBot::Commands::Base
      include SlackSup::Commands::Mixins::Subscribe

      def self.pluralize(count, text)
        case count
        when 1
          "#{count} #{text}"
        else
          "#{count} #{text.pluralize}"
        end
      end

      def self.parse_arg(match)
        max = 3
        arguments = match['expression'].split.reject(&:blank?) if match['expression']
        arguments ||= []
        number = arguments.shift
        if number
          max = case number.downcase
                when 'infinity'
                  nil
                else
                  Integer(number)
                end
        end
        max
      end

      subscribe_command 'rounds' do |client, data, match|
        max = parse_arg(match)
        team = client.owner
        messages = []
        messages << "Team S'Up facilitated #{pluralize(team.rounds.count, 'round')}."
        team.rounds.desc(:_id).take(max).each do |round|
          stats = RoundStats.new(round)
          ran_at = if round.ran_at && round.asked_at
                     round.ran_at.to_time.ago_in_words.gsub(/ and \d* \w*/, '')
                   elsif round.ran_at
                     'in progress'
                   else
                     'scheduled'
                   end
          messages << "* #{ran_at}: " \
            "#{pluralize(stats.sups_count, 'S\'Up')} " \
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
