require 'spec_helper'

describe SlackSup::App do
  subject do
    SlackSup::App.instance
  end

  describe '#instance' do
    it 'is an instance of the app' do
      expect(subject).to be_a(SlackRubyBotServer::App)
      expect(subject).to be_an_instance_of(SlackSup::App)
    end
  end

  describe '#purge_inactive_teams!' do
    it 'purges teams' do
      expect(Team).to receive(:purge!)
      subject.send(:purge_inactive_teams!)
    end
  end

  describe '#deactivate_asleep_teams!' do
    let!(:active_team) { Fabricate(:team, created_at: Time.now.utc) }
    let!(:active_team_one_week_ago) { Fabricate(:team, created_at: 1.week.ago) }
    let!(:active_team_three_weeks_ago) { Fabricate(:team, created_at: 3.weeks.ago) }
    let!(:subscribed_team_a_month_ago) { Fabricate(:team, created_at: 1.month.ago, subscribed: true) }

    it 'destroys teams inactive for two weeks' do
      expect_any_instance_of(Team).to receive(:inform!).with(
        "The S'Up bot hasn't been used for 3 weeks, deactivating. Reactivate at #{SlackRubyBotServer::Service.url}. Your data will be purged in another 2 weeks."
      ).once
      subject.send(:deactivate_asleep_teams!)
      expect(active_team.reload.active).to be true
      expect(active_team_one_week_ago.reload.active).to be true
      expect(active_team_three_weeks_ago.reload.active).to be false
      expect(subscribed_team_a_month_ago.reload.active).to be true
    end
  end

  context 'subscribed' do
    include_context 'stripe mock'
    let(:plan) { stripe_helper.create_plan(id: 'slack-sup-yearly', amount: 3999) }
    let(:customer) { Stripe::Customer.create(source: stripe_helper.generate_card_token, plan: plan.id, email: 'foo@bar.com') }
    let!(:team) { Fabricate(:team, subscribed: true, stripe_customer_id: customer.id) }

    describe '#check_subscribed_teams!' do
      it 'ignores active subscriptions' do
        expect_any_instance_of(Team).not_to receive(:inform!)
        subject.send(:check_subscribed_teams!)
      end

      it 'notifies past due subscription' do
        customer.subscriptions.data.first['status'] = 'past_due'
        expect(Stripe::Customer).to receive(:retrieve).and_return(customer)
        expect_any_instance_of(Team).to receive(:inform!).with("Your subscription to StripeMock Default Plan ID ($39.99) is past due. #{team.update_cc_text}")
        subject.send(:check_subscribed_teams!)
      end

      it 'notifies past due subscription' do
        customer.subscriptions.data.first['status'] = 'canceled'
        expect(Stripe::Customer).to receive(:retrieve).and_return(customer)
        expect_any_instance_of(Team).to receive(:inform!).with('Your subscription to StripeMock Default Plan ID ($39.99) was canceled and your team has been downgraded. Thank you for being a customer!')
        subject.send(:check_subscribed_teams!)
        expect(team.reload.subscribed?).to be false
      end
    end
  end

  context 'sup!' do
    let(:wday) { Time.now.utc.in_time_zone('Eastern Time (US & Canada)').wday }
    let(:team) { Fabricate(:team, sup_wday: wday, sup_time_of_day: 1) }

    it 'sups only active teams' do
      expect(team.sup?).to be true
      inactive_team = Fabricate(:team, sup_wday: wday, sup_time_of_day: 1, active: false)
      expect_any_instance_of(Team).to receive(:sup!).once.and_call_original
      expect_any_instance_of(Team).to receive(:sync!)
      subject.send(:sup!)
      expect(team.reload.sup?).to be false
      expect(inactive_team.reload.sup?).to be true
    end
  end

  context 'export_data!' do
    include_context 'uses temp dir'

    let!(:export1) { Fabricate(:export) }
    let!(:export2) { Fabricate(:export, exported: true) }

    it 'exports' do
      expect_any_instance_of(Export).to receive(:export!).once.and_call_original
      expect_any_instance_of(Export).to receive(:notify!)
      subject.send(:export_data!)
      expect(export1.reload.exported).to be true
    end
  end
end
