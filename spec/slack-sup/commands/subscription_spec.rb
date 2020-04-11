require 'spec_helper'

describe SlackSup::Commands::Subscription do
  let(:app) { SlackSup::Server.new(team: team) }
  let(:client) { app.send(:client) }
  shared_examples_for 'subscription' do
    include_context :stripe_mock
    context 'with a plan' do
      before do
        stripe_helper.create_plan(id: 'slack-sup-yearly', amount: 3999)
      end
      context 'a customer' do
        let!(:customer) do
          Stripe::Customer.create(
            source: stripe_helper.generate_card_token,
            plan: 'slack-sup-yearly',
            email: 'foo@bar.com'
          )
        end
        before do
          team.update_attributes!(subscribed: true, stripe_customer_id: customer['id'])
        end
        let(:active_subscription) { team.active_stripe_subscription }
        let(:current_period_end) { Time.at(active_subscription.current_period_end).strftime('%B %d, %Y') }
        it 'displays subscription info' do
          customer_info = "Customer since #{Time.at(customer.created).strftime('%B %d, %Y')}."
          customer_info += "\nSubscribed to StripeMock Default Plan ID ($39.99), will auto-renew on #{current_period_end}."
          card = customer.sources.first
          customer_info += "\nOn file Visa card, #{card.name} ending with #{card.last4}, expires #{card.exp_month}/#{card.exp_year}."
          customer_info += "\n#{team.update_cc_text}"
          expect(message: "#{SlackRubyBot.config.user} subscription").to respond_with_slack_message customer_info
        end
        it 'requires an admin user' do
          allow_any_instance_of(User).to receive(:team_admin?).and_return(false)
          expect(message: "#{SlackRubyBot.config.user} subscription").to respond_with_slack_message "Only <@#{team.activated_user_id}> or a Slack team admin can get subscription details, sorry."
        end
      end
    end
  end
  context 'unsubscribed team', vcr: { cassette_name: 'user_info' } do
    let!(:team) { Fabricate(:team) }
    it 'is a subscription feature' do
      expect(message: "#{SlackRubyBot.config.user} subscription").to respond_with_slack_message(
        "Subscribe your team for $39.99 a year at #{SlackRubyBotServer::Service.url}/subscribe?team_id=#{team.team_id}."
      )
    end
  end
  context 'subscribed team' do
    let!(:team) { Fabricate(:team, subscribed: true) }
    let!(:activated_user) { Fabricate(:user, team: team) }
    context 'as admin' do
      before do
        expect(User).to receive(:find_create_or_update_by_slack_id!).and_return(activated_user)
        team.update_attributes!(activated_user_id: activated_user.user_id)
      end
      context 'subscribed team without a customer ID' do
        before do
          team.update_attributes!(subscribed: true, stripe_customer_id: nil)
        end
        it 'reports subscribed' do
          expect(message: "#{SlackRubyBot.config.user} subscription", user: 'user').to respond_with_slack_message(
            'Team is subscribed.'
          )
        end
      end
      it_behaves_like 'subscription'
      context 'with another team' do
        let!(:team2) { Fabricate(:team) }
        it_behaves_like 'subscription'
      end
    end
  end
end
