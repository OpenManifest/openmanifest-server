module DailyLogEntry::Slot
  extend ActiveSupport::Concern

  included do
    # Extract the important information from the load
    # to JSON for the master log
    #
    # @return [Hash]
    def to_daily_log
      slice(:id).merge(
        name: guest&.name || membership&.user&.name,
        altitude: ticket_type.altitude,
        activity_type: activity_type.name,
      )
    end
  end
end
