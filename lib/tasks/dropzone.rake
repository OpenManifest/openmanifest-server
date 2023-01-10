namespace :dropzone do
  namespace :master_log do
    task :generate => :environment do
      MasterLog::Schedule.run!
    end
  end

  namespace :loads do
    task :finalize => :environment do
      Manifest::Schedule::AutoFinalize.run
    end
  end
end
