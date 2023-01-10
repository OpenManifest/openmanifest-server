module MasterLogEntry::Load
  extend ActiveSupport::Concern

  included do
    # Extract the important information from the load
    # to JSON for the master log
    #
    # @return [Hash]
    def to_master_log
      slice(:load_number, :name).merge(
        dispatch_at: dispatch_at&.iso8601,
        gca: gca&.to_master_log,
        load_master: load_master&.to_master_log,
        aircraft: plane&.to_master_log,
        slots: slots.map(&:to_master_log),
      )
    end
  end
end
