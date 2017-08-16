desc 'Sup cron.'
namespace :cron do
  task :weekly do
    Team.active.asc(:_id).each do |team|
      begin
        logger.info "Running cron for #{team}."
        team.sync!
        team.users.each(&:introduce_sup!)
        round = Round.for(team)
        logger.info "Setup round #{round}, finished cron."
      rescue StandardError => e
        logger.warn "Error in cron for team #{team}, #{e.message}."
        raise
      end
    end
  end
end
