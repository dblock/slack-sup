module SlackSup
  module Commands
    class Unsubscribe < SlackRubyBot::Commands::Base
      include SlackSup::Commands::Mixins::User

      subscribe_command 'unsubscribe' do |client, data, match|
        if !client.owner.stripe_customer_id
          client.say(channel: data.channel, text: "You don't have a paid subscription, all set.")
          logger.info "UNSUBSCRIBE: #{client.owner} - #{data.user} unsubscribe failed, no subscription"
        elsif client.owner.is_admin?(data.user) && client.owner.active_stripe_subscription?
          subscription_info = []
          subscription_id = match['expression']
          active_subscription = client.owner.active_stripe_subscription
          if active_subscription && active_subscription.id == subscription_id
            active_subscription.delete(at_period_end: true)
            amount = ActiveSupport::NumberHelper.number_to_currency(active_subscription.plan.amount.to_f / 100)
            subscription_info << "Successfully canceled auto-renew for #{active_subscription.plan.name} (#{amount})."
            logger.info "UNSUBSCRIBE: #{client.owner} - #{data.user}, canceled #{subscription_id}"
          elsif subscription_id
            subscription_info << "Sorry, I cannot find a subscription with \"#{subscription_id}\"."
          else
            subscription_info.concat(client.owner.stripe_customer_subscriptions_info(true))
          end
          client.say(channel: data.channel, text: subscription_info.compact.join("\n"))
          logger.info "UNSUBSCRIBE: #{client.owner} - #{data.user}"
        else
          client.say(channel: data.channel, text: "Only <@#{client.owner.activated_user_id}> or a Slack team admin can unsubscribe, sorry.")
          logger.info "UNSUBSCRIBE: #{client.owner} - #{data.user} unsubscribe failed, not admin"
        end
      end
    end
  end
end
