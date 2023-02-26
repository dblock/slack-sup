module SlackSup
  module Commands
    class Subscription < SlackRubyBot::Commands::Base
      include SlackSup::Commands::Mixins::User

      subscribe_command 'subscription' do |client, data, _match|
        if client.owner.is_admin?(data.user)
          subscription_info = []
          if client.owner.active_stripe_subscription?
            subscription_info << client.owner.stripe_customer_text
            subscription_info.concat(client.owner.stripe_customer_subscriptions_info)
            subscription_info.concat(client.owner.stripe_customer_invoices_info)
            subscription_info.concat(client.owner.stripe_customer_sources_info)
            subscription_info << client.owner.update_cc_text
          elsif client.owner.subscribed && client.owner.subscribed_at
            subscription_info << client.owner.subscriber_text
          else
            subscription_info << client.owner.trial_message
          end
          client.say(channel: data.channel, text: subscription_info.compact.join("\n"))
        else
          client.say(channel: data.channel, text: "Only <@#{client.owner.activated_user_id}> or a Slack team admin can get subscription details, sorry.")
        end
        logger.info "SUBSCRIPTION: #{data.user}"
      end
    end
  end
end
