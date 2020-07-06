module SlackSup
  module Commands
    class Next < SlackRubyBot::Commands::Base
      include SlackSup::Commands::Mixins::Subscribe

      subscribe_command 'next' do |client, data, _match|
        team = client.owner
        next_sup_at = team.next_sup_at
        messages = [
          'Next round is',
          Time.now > next_sup_at ? 'overdue' : nil,
          next_sup_at.strftime('%A, %B %e, %Y at %l:%M %p %Z').gsub('  ', ' '),
          '(' + next_sup_at.to_time.ago_or_future_in_words(highest_measure_only: true) + ').'
        ].compact.join(' ')
        client.say(channel: data.channel, text: messages)
        logger.info "NEXT: #{client.owner} - #{data.user}"
      end
    end
  end
end
