module MasterLogEntry::Dropzone
  extend ActiveSupport::Concern

  included do
    # Extract the important information from the dropzone
    # to JSON for the master log
    #
    # @return [Hash]
    def to_master_log(date = nil)
      date ||= DateTime.current
      {
        date: date.iso8601,
        location: slice(:lat, :lng),
        loads: loads.where(dispatch_at: date.all_day).where.not(state: %i(cancelled)).order(load_number: :asc).map(&:to_master_log),
      }
    end
  end
end
