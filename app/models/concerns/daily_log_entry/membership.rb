module DailyLogEntry::Membership
  extend ActiveSupport::Concern

  included do
    # Extract the important information from the load
    # to JSON for the master log
    #
    # @return [Hash]
    def to_daily_log
      slice(:id).merge(user.slice(:name, :nickname, :phone, :email))
    end
  end
end
