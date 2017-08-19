module SlackSup
  class App < SlackRubyBotServer::App
    include Celluloid

    def prepare!
      super
      deactivate_asleep_teams!
    end

    def after_start!
      logger.info 'Starting sup and subscription crons.'
      once_and_every 60 * 60 * 24 * 3 do
        check_subscribed_teams!
        check_expired_subscriptions!
      end
      once_and_every 60 * 30 do
        sup!
      end
      once_and_every 60 * 30 do
        ask!
      end
    end

    private

    def once_and_every(tt)
      yield
      every tt do
        yield
      end
    end

    def ask!
      Team.active.each do |team|
        begin
          last_sup_at = team.last_sup_at
          logger.info "Checking #{team}, #{last_sup_at ? 'last sup ' + last_sup_at.ago_in_words : 'first time sup'}."
          round = team.ask!
          logger.info "Asked about previous sup round #{round}." if round
        rescue StandardError => e
          logger.warn "Error in cron for team #{team}, #{e.message}."
        end
      end
    end

    def sup!
      Team.active.each do |team|
        begin
          last_sup_at = team.last_sup_at
          logger.info "Checking #{team}, #{last_sup_at ? 'last sup ' + last_sup_at.ago_in_words : 'first time sup'}."
          next unless team.sup?
          round = team.sup!
          logger.info "Created sup round #{round}."
        rescue StandardError => e
          logger.warn "Error in cron for team #{team}, #{e.message}."
        end
      end
    end

    def check_expired_subscriptions!
      Team.active.where(subscribed: false).each do |team|
        logger.info "Checking #{team} created #{team.created_at.ago_in_words}, subscription #{team.subscription_expired? ? 'has expired' : 'is active'}."
        next unless team.subscription_expired?
        team.inform! team.subscribe_text
      end
    end

    def deactivate_asleep_teams!
      Team.active.each do |team|
        next unless team.asleep?
        begin
          team.deactivate!
          team.inform! "The S'Up bot hasn't been used for 3 weeks, deactivating. Reactivate at #{SlackSup::Service.url}. Your data will be purged in another 2 weeks."
        rescue StandardError => e
          logger.warn "Error informing team #{team}, #{e.message}."
        end
      end
    end

    def check_subscribed_teams!
      Team.where(subscribed: true, :stripe_customer_id.ne => nil).each do |team|
        begin
          customer = Stripe::Customer.retrieve(team.stripe_customer_id)
          customer.subscriptions.each do |subscription|
            subscription_name = "#{subscription.plan.name} (#{ActiveSupport::NumberHelper.number_to_currency(subscription.plan.amount.to_f / 100)})"
            logger.info "Checking #{team} subscription to #{subscription_name}, #{subscription.status}."
            case subscription.status
            when 'past_due'
              logger.warn "Subscription for #{team} is #{subscription.status}, notifying."
              team.inform! "Your subscription to #{subscription_name} is past due. #{team.update_cc_text}"
            when 'canceled', 'unpaid'
              logger.warn "Subscription for #{team} is #{subscription.status}, downgrading."
              team.inform! "Your subscription to #{subscription.plan.name} (#{ActiveSupport::NumberHelper.number_to_currency(subscription.plan.amount.to_f / 100)}) was canceled and your team has been downgraded. Thank you for being a customer!"
              team.update_attributes!(subscribed: false)
            end
          end
        rescue StandardError => e
          logger.warn "Error informing team #{team}, #{e.message}."
        end
      end
    end
  end
end
