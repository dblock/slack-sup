require 'slack-sup/service'

SlackRubyBotServer::Stripe.configure do |config|
  config.root_url = SlackRubyBotServer::Service.url
  config.subscription_plan_id = 'slack-sup-yearly'
end
