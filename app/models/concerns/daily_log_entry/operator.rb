module DailyLogEntry::Operator
  extend ActiveSupport::Concern

  included do
    # Extract the important information from the operator
    # to JSON for the master log
    #
    # @return [Hash]
    def to_daily_log(date = nil)
      date ||= Time.current.in_time_zone(time_zone).to_date
      # The day is the operator's, not the server's
      day = date.in_time_zone(time_zone).all_day
      {
        date: date.iso8601,
        location: slice(:lat, :lng),
        loads: loads.where(dispatch_at: day).where.not(state: %i(cancelled)).order(load_number: :asc).map(&:to_daily_log),
      }
    end
  end
end
