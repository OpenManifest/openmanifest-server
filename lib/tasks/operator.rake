namespace :operator do
  namespace :daily_log do
    # Scheduled by config/recurring.yml; this runs it once, now
    task :generate => :environment do
      DailyLogsJob.perform_now
    end
  end

  namespace :loads do
    task :finalize => :environment do
      AutoFinalizeJob.perform_now
    end
  end
end
