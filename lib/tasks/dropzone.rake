namespace :dropzone do
  namespace :master_log do
    # Scheduled by config/recurring.yml; this runs it once, now
    task :generate => :environment do
      MasterLogsJob.perform_now
    end
  end

  namespace :loads do
    task :finalize => :environment do
      AutoFinalizeJob.perform_now
    end
  end
end
