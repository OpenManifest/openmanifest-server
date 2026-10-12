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
        altitude: (destination || ticket_type.default_destination)&.altitude_ft,
        activity_type: activity_type.name,
      )
    end
  end
end
