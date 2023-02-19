module SlackSup
  module Commands
    class Subscription < SlackRubyBot::Commands::Base
      include SlackSup::Commands::Mixins::User

      user_command 'subscription' do |client, _channel, user, data, _match|
        if user.team_admin?
          subscription_info = []
          if user.channel.team.active_stripe_subscription?
            subscription_info << user.channel.team.stripe_customer_text
            subscription_info.concat(user.channel.team.stripe_customer_subscriptions_info)
            if user.team_admin?
              subscription_info.concat(user.channel.team.stripe_customer_invoices_info)
              subscription_info.concat(user.channel.team.stripe_customer_sources_info)
              subscription_info << user.channel.team.update_cc_text
            end
          elsif user.channel.team.subscribed && user.channel.team.subscribed_at
            subscription_info << user.channel.team.subscriber_text
          else
            subscription_info << user.channel.team.trial_message
          end
          client.say(channel: data.channel, text: subscription_info.compact.join("\n"))
        else
          client.say(channel: data.channel, text: "Only <@#{user.channel.team.activated_user_id}> or a Slack team admin can get subscription details, sorry.")
        end
        logger.info "SUBSCRIPTION: #{client.owner} - #{user.user_name}"
      end
    end
  end
end
