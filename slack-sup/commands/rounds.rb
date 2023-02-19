module SlackSup
  module Commands
    class Rounds < SlackRubyBot::Commands::Base
      include SlackSup::Commands::Mixins::Channel
      include SlackSup::Commands::Mixins::Pluralize

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

      def self.percent_s(count, total, no = 'no')
        pc = count && count > 0 ? count * 100 / total : 0
        pc > 0 ? "#{pc}%" : no
      end

      channel_command 'rounds' do |client, channel, data, match|
        max = parse_arg(match)
        messages = []
        messages << "Team S'Up facilitated #{pluralize(channel.rounds.count, 'round')}."
        channel.rounds.desc(:_id).take(max).each do |round|
          stats = RoundStats.new(round)
          ran_at = if round.ran_at && round.asked_at
                     round.ran_at.to_time.ago_in_words(highest_measure_only: true)
                   elsif round.ran_at
                     'in progress'
                   else
                     'scheduled'
                   end
          messages << "* #{ran_at}: #{pluralize(stats.sups_count, 'S\'Up')} " + [
            "paired #{pluralize(stats.users_in_sups_count, 'user')}",
            stats.sups_count && stats.sups_count > 0 && stats.reported_outcomes_count && stats.reported_outcomes_count > 0 ? percent_s(stats.positive_outcomes_count, stats.sups_count) + ' positive outcomes' : nil,
            stats.sups_count && stats.sups_count > 0 ? percent_s(stats.reported_outcomes_count, stats.sups_count) + ' outcomes reported' : nil,
            stats.round.opted_out_users_count && stats.round.opted_out_users_count > 0 ? pluralize(stats.round.opted_out_users_count, 'opt out').to_s : nil,
            stats.round.missed_users_count && stats.round.missed_users_count > 0 ? pluralize(stats.round.missed_users_count, 'missed user').to_s : nil
          ].compact.and + '.'
        end
        client.say(channel: data.channel, text: messages.join("\n"))
        logger.info "STATS: #{channel} - #{data.user}"
      end
    end
  end
end
