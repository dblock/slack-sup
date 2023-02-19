module SlackSup
  module Commands
    class Stats < SlackRubyBot::Commands::Base
      include SlackSup::Commands::Mixins::Channel
      include SlackSup::Commands::Mixins::Pluralize

      channel_command 'stats' do |client, channel, data, _match|
        stats = ::Stats.new(channel)
        messages = []
        messages << "Team S'Up connects groups of #{channel.sup_size} people on #{channel.sup_day} after #{channel.sup_time_of_day_s} every #{channel.sup_every_n_weeks_s}."
        messages << if stats.users_count > 0 && stats.users_opted_in_count > 0
                      "Team S'Up started #{channel.created_at.ago_in_words(highest_measure_only: true)} with #{stats.users_opted_in_count * 100 / stats.users_count}% (#{stats.users_opted_in_count}/#{stats.users_count}) of users opted in."
                    else
                      "Team S'Up started #{channel.created_at.ago_in_words(highest_measure_only: true)} with no users (0/#{stats.users_count}) opted in."
                    end
        if stats.sups_count > 0
          messages << "Facilitated #{pluralize(stats.sups_count, 'S\'Up')} " \
            "in #{pluralize(stats.rounds_count, 'round')} " \
            "for #{pluralize(stats.users_in_sups_count, 'user')} " \
            "with #{stats.positive_outcomes_count * 100 / stats.sups_count}% positive outcomes " \
            "from #{stats.reported_outcomes_count * 100 / stats.sups_count}% outcomes reported."
        end
        client.say(channel: channel.channel_id, text: messages.join("\n"))
        logger.info "STATS: #{channel} - #{data.user}"
      end
    end
  end
end
