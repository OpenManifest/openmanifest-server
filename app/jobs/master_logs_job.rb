# frozen_string_literal: true

# Generates the master log of yesterday for the dropzones that are between 02:00 and 02:59 local time (and, should a run
# have been missed, for those past that hour that flew yesterday and have no log yet). Runs every hour
# (config/recurring.yml): a dropzone is in its 02:xx hour once a day, in whichever time zone it is.
class MasterLogsJob < ApplicationJob
  queue_as :default

  GENERATION_HOUR = 2

  def perform(now = Time.current)
    Dropzone.find_each do |dropzone|
      local = now.in_time_zone(dropzone.time_zone)
      yesterday = local.to_date - 1
      next unless local.hour == GENERATION_HOUR || (local.hour > GENERATION_HOUR && missed?(dropzone, yesterday))

      MasterLog::Generate.run!(dropzone: dropzone, date: yesterday)
    end
  end

  private

  def missed?(dropzone, date)
    return false if dropzone.master_logs.exists?(date: date)

    dropzone.loads.exists?(dispatch_at: date.in_time_zone(dropzone.time_zone).all_day)
  end
end
