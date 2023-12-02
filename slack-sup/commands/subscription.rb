module SlackSup
  module Commands
    class Subscription < SlackRubyBot::Commands::Base
      include SlackSup::Commands::Mixins::Subscribe

      subscribe_command 'subscription' do |client, data, _match|
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        team = ::Team.find(client.owner.id)
        if user.team_admin?
          subscription_info = []
          if team.stripe_subcriptions&.any?
            subscription_info << team.stripe_customer_text
            subscription_info.concat(team.stripe_customer_subscriptions_info)
            subscription_info.concat(team.stripe_customer_invoices_info)
            subscription_info.concat(team.stripe_customer_sources_info)
            subscription_info << team.update_cc_text
          elsif team.subscribed && team.subscribed_at
            subscription_info << team.subscriber_text
          else
            subscription_info << team.trial_message
          end
          client.say(channel: data.channel, text: subscription_info.compact.join("\n"))
        else
          client.say(channel: data.channel, text: "Only #{team.team_admins_slack_mentions} can get subscription details, sorry.")
        end
        logger.info "SUBSCRIPTION: #{client.owner} - #{user.user_name}"
      end
    end
  end
end
