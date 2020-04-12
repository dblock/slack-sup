module SlackSup
  module Commands
    class Unsubscribe < SlackRubyBot::Commands::Base
      include SlackSup::Commands::Mixins::Subscribe

      subscribe_command 'unsubscribe' do |client, data, match|
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        team = ::Team.find(client.owner.id)
        if !team.stripe_customer_id
          client.say(channel: data.channel, text: "You don't have a paid subscription, all set.")
          logger.info "UNSUBSCRIBE: #{client.owner} - #{user.user_name} unsubscribe failed, no subscription"
        elsif user.team_admin? && team.active_stripe_subscription?
          subscription_info = []
          subscription_id = match['expression']
          active_subscription = team.active_stripe_subscription
          if active_subscription && active_subscription.id == subscription_id
            team.unsubscribe!
            amount = ActiveSupport::NumberHelper.number_to_currency(active_subscription.plan.amount.to_f / 100)
            subscription_info << "Successfully canceled auto-renew for #{active_subscription.plan.name} (#{amount})."
            logger.info "UNSUBSCRIBE: #{client.owner} - #{data.user}, canceled #{subscription_id}"
          elsif subscription_id
            subscription_info << "Sorry, I cannot find a subscription with \"#{subscription_id}\"."
          else
            subscription_info << team.send(:stripe_customer_subscriptions_info)
            subscription_info << "Send `unsubscribe #{active_subscription.id}` to unsubscribe."
          end
          client.say(channel: data.channel, text: subscription_info.compact.join("\n"))
          logger.info "UNSUBSCRIBE: #{client.owner} - #{data.user}"
        else
          client.say(channel: data.channel, text: "Only <@#{team.activated_user_id}> or a Slack team admin can unsubscribe, sorry.")
          logger.info "UNSUBSCRIBE: #{client.owner} - #{user.user_name} unsubscribe failed, not admin"
        end
      end
    end
  end
end
