namespace :dropzone do
  namespace :master_log do
    task :generate => :environment do
      # Find what time zones its currently past midnight in
      midnight_zones = ActiveSupport::TimeZone.all.select do |zone|
        Time.use_zone(zone) do
          DateTime.current.to_time.hour == 0
        end
      end.map(&:tzinfo).map(&:name)

      # Find all dropzones in these timezones
      dropzones = Dropzone.where(time_zone: midnight_zones)
      next puts "No Dropzones in #{midnight_zones.join(", ")}" if dropzones.empty?

      dropzones.each do |dropzone|
        puts "Generating master log entry for #{dropzone.name}"
        Time.use_zone(dropzone.time_zone) do
          MasterLog::Generate.run(
            dropzone: dropzone,
            date: 1.day.ago.to_datetime
          )
        end
      end
    end
  end
end
