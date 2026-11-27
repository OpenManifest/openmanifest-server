module DailyLogEntry::Slot
  extend ActiveSupport::Concern

  included do
    # Extract the important information from the slot for the daily log: who rode (a member or the guest of an escort),
    # how to reach them and who to call for them (the guest list of the boat templates), the ticket, and for skydiving the
    # altitude and the activity. A guest without an emergency contact of their own has their escort's.
    #
    # @return [Hash]
    def to_daily_log
      person = guest || membership&.user
      escort = escort_slot&.membership&.user
      slice(:id).merge(
        name: person&.name,
        phone: person&.phone,
        email: person&.email,
        emergency_contact: person&.emergency_contact.presence || escort_contact(escort),
        ticket_type: ticket_type&.name,
        escort: escort&.name,
        altitude_m: (destination || ticket_type.default_destination)&.altitude_m&.to_f,
        # Operators without the activities module (whale watching, snorkel) have no activity (BUG-134)
        activity_type: activity_type&.name,
      )
    end

    private

    def escort_contact(escort)
      return nil unless escort

      [escort.name, escort.phone.presence].compact.join(" ")
    end
  end
end
