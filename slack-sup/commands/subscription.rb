module SlackSup
  module Commands
    class Subscription < SlackRubyBot::Commands::Base
      include SlackSup::Commands::Mixins::Subscribe

      subscribe_command 'subscription' do |client, data, _match|
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        team = ::Team.find(client.owner.id)
        subscription_info = team.subscription_info(include_admin_info: user.team_admin?)
        client.say(channel: data.channel, text: subscription_info)
        logger.info "SUBSCRIPTION: #{client.owner} - #{user.user_name}"
      end
    end
  end
end
