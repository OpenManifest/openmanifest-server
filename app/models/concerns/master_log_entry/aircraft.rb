module MasterLogEntry::Aircraft
  extend ActiveSupport::Concern

  included do
    # Extract the important information from the load
    # to JSON for the master log
    #
    # @return [Hash]
    def to_master_log
      slice(
        :name,
        :registration
      )
    end
  end
end
