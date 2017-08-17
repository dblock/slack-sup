module SlackSup
  module Commands
    class Opt < SlackRubyBot::Commands::Base
      include SlackSup::Commands::Mixins::Subscribe

      subscribe_command 'opt' do |client, data, match|
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        expression = match['expression'] if match['expression']
        case expression
        when 'in' then
          user.update_attributes!(opted_in: true)
        when 'out' then
          user.update_attributes!(opted_in: false)
        when nil, '' then
          # ignore
        else
          raise "You can _opt in_ or _opt out_, but not _opt #{expression}_."
        end
        client.say(channel: data.channel, text: "Hi there #{user.slack_mention}, you're #{expression ? 'now ' : ''}opted #{user.opted_in? ? 'into' : 'out of'} S'Up.")
        logger.info "OPT: #{client.owner}: #{user} - #{user.opted_in? ? 'in' : 'out'}"
      end
    end
  end
end
