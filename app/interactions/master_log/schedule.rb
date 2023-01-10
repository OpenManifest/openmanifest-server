class MasterLog::Schedule < ApplicationInteraction
  steps :check_dropzones, :generate_logs

  def check_dropzones
    errors.add(:base, 'No dropzones in midnight timezones') if dropzones_at_midnight.empty?
  end

  def generate_logs
    dropzones_at_midnight.each do |dropzone|
      puts "Generating master log entry for #{dropzone.name}"
      Time.use_zone(dropzone.time_zone) do
        MasterLog::Generate.run(
          dropzone: dropzone,
          date: 1.day.ago.to_datetime
        )
      end
    end
  end

  private

  # Get all dropzones in a timezone where its midnight
  def dropzones_at_midnight
    Dropzone.where(time_zone: time_zones_in_midnight)
  end

  # Get all timezones where its currently midnight hour
  def time_zones_in_midnight
    ActiveSupport::TimeZone.all.select do |zone|
      Time.use_zone(zone) do
        DateTime.current.to_time.hour == 0
      end
    end.map(&:tzinfo).map(&:name)
  end
end
