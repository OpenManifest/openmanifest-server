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
        departed_at: departed_at&.iso8601,
        completed_at: completed_at&.iso8601,
        gca: gca&.to_daily_log,
        load_master: load_master&.to_daily_log,
        vehicle: vehicle&.to_daily_log,
        vehicles: load_vehicles.map { |load_vehicle| load_vehicle.vehicle.to_daily_log.merge(role: load_vehicle.role) },
        pilot: pilot&.to_daily_log,
        # Everyone on the crew by the operator's own role names (skipper, deckhand, ...)
        crew: crew_assignments.includes(:crew_role, membership: :user).sort_by { |assignment| [assignment.crew_role.position.to_i, assignment.id] }.map do |assignment|
          assignment.membership.to_daily_log.merge(role: assignment.crew_role.name)
        end,
        destinations: destinations.map(&:name),
        # Escorts first, each followed by their guests
        slots: slots.includes(:guest, :ticket_type, :activity_type, :destination, membership: :user, escort_slot: { membership: :user }).
          sort_by { |slot| [slot.escort_slot_id || slot.id, slot.escort_slot_id ? 1 : 0, slot.id] }.map(&:to_daily_log),
      )
    end
  end
end
