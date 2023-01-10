module MasterLogEntry::Slot
  extend ActiveSupport::Concern

  included do
    # Extract the important information from the load
    # to JSON for the master log
    #
    # @return [Hash]
    def to_master_log
      {
        name: passenger&.name || dropzone_user&.user&.name,
        altitude: ticket_type.altitude,
        jump_type: jump_type.name,
      }
    end
  end
end
