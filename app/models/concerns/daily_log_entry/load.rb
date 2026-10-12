module DailyLogEntry::Load
  extend ActiveSupport::Concern

  included do
    # Extract the important information from the load
    # to JSON for the master log
    #
    # @return [Hash]
    def to_daily_log
      slice(:load_number, :name, :id).merge(
        dispatch_at: dispatch_at&.iso8601,
        gca: gca&.to_daily_log,
        load_master: load_master&.to_daily_log,
        vehicle: vehicle&.to_daily_log,
        pilot: pilot&.to_daily_log,
        slots: slots.map(&:to_daily_log),
      )
    end
  end
end
