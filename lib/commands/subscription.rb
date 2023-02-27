module SlackSup
  module Commands
    class Subscription < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackSup::Commands::Mixins::User

      subscribe_command 'subscription' do |data|
        if data.team.is_admin?(data.user)
          subscription_info = []
          if data.team.active_stripe_subscription?
            subscription_info << data.team.stripe_customer_text
            subscription_info.concat(data.team.stripe_customer_subscriptions_info)
            subscription_info.concat(data.team.stripe_customer_invoices_info)
            subscription_info.concat(data.team.stripe_customer_sources_info)
            subscription_info << data.team.update_cc_text
          elsif data.team.subscribed && data.team.subscribed_at
            subscription_info << data.team.subscriber_text
          else
            subscription_info << data.team.trial_message
          end
          data.team.slack_client.chat_postMessage(channel: data.channel, text: subscription_info.compact.join("\n"))
        else
          data.team.slack_client.chat_postMessage(channel: data.channel, text: "Only <@#{data.team.activated_user_id}> or a Slack team admin can get subscription details, sorry.")
        end
        logger.info "SUBSCRIPTION: #{data.team}, user=#{data.user}"
      end
    end
  end
end
