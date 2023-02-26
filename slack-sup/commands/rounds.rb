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

      channel_command 'rounds' do |client, channel, data, match|
        max = parse_arg(match)
        messages = []
        if channel
          messages << "Channel S'Up facilitated #{pluralize(channel.rounds.count, 'round')}."
          channel.rounds.desc(:_id).limit(max).each do |round|
            messages << RoundStats.new(round).to_s
          end
        else
          messages << "Team S'Up facilitated #{pluralize(client.owner.rounds.count, 'round')} in #{pluralize(client.owner.channels.count, 'channel')}."
          client.owner.rounds.desc(:_id).limit(max).each do |round|
            messages << RoundStats.new(round).to_s(true)
          end
        end
        client.say(channel: data.channel, text: messages.join("\n"))
        logger.info "STATS: #{data.channel} - #{data.user}"
      end
    end
  end
end
