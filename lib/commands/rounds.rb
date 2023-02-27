module SlackSup
  module Commands
    class Rounds < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackSup::Commands::Mixins::Channel
      include SlackSup::Commands::Mixins::Pluralize

      def self.parse_arg(data)
        max = 3
        arguments = data.match['expression'].split.reject(&:blank?) if data.match['expression']
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

      channel_command 'rounds' do |channel, data|
        max = parse_arg(data)
        messages = []
        if channel
          messages << "Channel S'Up facilitated #{pluralize(channel.rounds.count, 'round')}."
          channel.rounds.desc(:_id).limit(max).each do |round|
            messages << RoundStats.new(round).to_s
          end
        else
          messages << "Team S'Up facilitated #{pluralize(data.team.rounds.count, 'round')} in #{pluralize(data.team.channels.count, 'channel')}."
          data.team.rounds.desc(:_id).limit(max).each do |round|
            messages << RoundStats.new(round).to_s(true)
          end
        end
        data.team.slack_client.chat_postMessage(channel: data.channel, text: messages.join("\n"))
        logger.info "STATS: #{data.team}, channel=#{data.channel}, user=#{data.user}"
      end
    end
  end
end
