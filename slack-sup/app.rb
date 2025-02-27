module SlackSup
  class App < SlackRubyBotServer::App
    def prepare!
      super
      deactivate_asleep_teams!
    end

    def after_start!
      ::Async::Reactor.run do
        logger.info 'Starting sup and subscription crons.'
        once_and_every 60 * 60 * 24 * 3 do
          check_subscribed_teams!
          check_expired_subscriptions!
        end
        once_and_every 60 * 30 do
          sync!
          sup!
        end
        once_and_every 60 * 30 do
          remind!
          ask!
          ask_again!
        end
        once_and_every 60 do
          export_data!
        end
      end
    end

    private

    def once_and_every(tt)
      ::Async::Reactor.run do |task|
        loop do
          yield
          task.sleep tt
        end
      end
    end

    def invoke_with_criteria!(teams, &)
      teams.each do |team|
        yield team
      rescue StandardError => e
        backtrace = e.backtrace.join("\n")
        logger.warn "Error in cron for team #{team}, #{e.message}, #{backtrace}."
      end
    end

    def invoke!(&)
      invoke_with_criteria!(Team.active, &)
    end

    def ask!
      invoke! do |team|
        last_round_at = team.last_round_at
        logger.info "Checking whether to ask #{team}, #{last_round_at ? 'last round ' + last_round_at.ago_in_words : 'first time sup'}."
        round = team.ask!
        logger.info "Asked about previous sup round #{round}." if round
      end
    end

    def ask_again!
      invoke! do |team|
        last_round_at = team.last_round_at
        logger.info "Checking whether to ask again #{team}, #{last_round_at ? 'last round ' + last_round_at.ago_in_words : 'first time sup'}."
        round = team.ask_again!
        logger.info "Asked again about previous sup round #{round}." if round
      end
    end

    def remind!
      invoke! do |team|
        last_round_at = team.last_round_at
        logger.info "Checking whether to remind #{team}, #{last_round_at ? 'last round ' + last_round_at.ago_in_words : 'first time sup'}."
        round = team.remind!
        logger.info "Reminded about previous sup round #{round}." if round
      end
    end

    def sync!
      invoke_with_criteria!(Team.active.where(sync: true)) do |team|
        tt = Time.now.utc
        team.sync!
        logger.info "Synched #{team}, #{team.users.where(:updated_at.gte => tt).count} user(s) updated."
      end
    end

    def sup!
      invoke! do |team|
        last_round_at = team.last_round_at
        logger.info "Checking whether to sup #{team}, #{last_round_at ? 'last round ' + last_round_at.ago_in_words : 'first time sup'}."
        next unless team.sup?

        round = team.sup!
        logger.info "Created sup round #{round}."
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
          team.inform! "The S'Up bot hasn't been used for 3 weeks, deactivating. Reactivate at #{SlackRubyBotServer::Service.url}. Your data will be purged in another 2 weeks."
        rescue StandardError => e
          logger.warn "Error informing team #{team}, #{e.message}."
        end
      end
    end

    def check_subscribed_teams!
      Team.where(subscribed: true, :stripe_customer_id.ne => nil).each do |team|
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
        if customer.subscriptions.none?
          logger.info "No active subscriptions for #{team} (#{team.stripe_customer_id}), downgrading."
          team.inform! 'Your subscription was canceled and your team has been downgraded. Thank you for being a customer!'
          team.update_attributes!(subscribed: false)
        end
      rescue StandardError => e
        logger.warn "Error informing team #{team}, #{e.message}."
      end
    end

    def export_data!
      invoke_with_criteria!(Export.requested) do |export|
        export.export!
      end
    end
  end
end
