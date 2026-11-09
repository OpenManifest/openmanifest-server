# frozen_string_literal: true

# Creates the master log entry of a day, or refreshes the stored JSON of the existing one. The day is a date in the
# operator's time zone (yesterday's, by default: the log is written once the day is over).
class DailyLog::Generate < ApplicationInteraction
  record :operator
  date :date, default: nil

  steps :generate

  def generate
    entry = operator.daily_logs.find_or_initialize_by(date: log_date)
    # A new entry stores its JSON when it is created
    entry.new_record? ? entry.save! : entry.store!
    entry
  end

  private

  def log_date
    date || (Time.current.in_time_zone(operator.time_zone).to_date - 1)
  end
end
