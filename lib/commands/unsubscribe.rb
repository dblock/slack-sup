module SlackSup
  module Commands
    class Unsubscribe < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackSup::Commands::Mixins::User

      subscribe_command 'unsubscribe' do |data|
        if !data.team.stripe_customer_id
          data.team.slack_client.chat_postMessage(channel: data.channel, text: "You don't have a paid subscription, all set.")
          logger.info "UNSUBSCRIBE: #{data.team}, user=#{data.user} unsubscribe failed, no subscription"
        elsif data.team.is_admin?(data.user) && data.team.active_stripe_subscription?
          subscription_info = []
          subscription_id = data.match['expression']
          active_subscription = data.team.active_stripe_subscription
          if active_subscription && active_subscription.id == subscription_id
            active_subscription.delete(at_period_end: true)
            amount = ActiveSupport::NumberHelper.number_to_currency(active_subscription.plan.amount.to_f / 100)
            subscription_info << "Successfully canceled auto-renew for #{active_subscription.plan.name} (#{amount})."
            logger.info "UNSUBSCRIBE: #{data.team}, user=#{data.user}, canceled #{subscription_id}"
          elsif subscription_id
            subscription_info << "Sorry, I cannot find a subscription with \"#{subscription_id}\"."
          else
            subscription_info.concat(data.team.stripe_customer_subscriptions_info(true))
          end
          data.team.slack_client.chat_postMessage(channel: data.channel, text: subscription_info.compact.join("\n"))
          logger.info "UNSUBSCRIBE: #{data.team}, user=#{data.user}"
        else
          data.team.slack_client.chat_postMessage(channel: data.channel, text: "Only <@#{data.team.activated_user_id}> or a Slack team admin can unsubscribe, sorry.")
          logger.info "UNSUBSCRIBE: #{data.team}, user=#{data.user} unsubscribe failed, not admin"
        end
      end
    end
  end
end
