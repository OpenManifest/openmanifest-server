# frozen_string_literal: true

module Eligibility
  module Rules
    # Room on the load, and in the vehicle when the slot rides in one in particular: a seat for the slot and for each guest
    class Capacity < Rule
      def check(context)
        load = context.load
        return if load.nil?
        return pass("capacity") if context.summary? && load.available_slots.positive?
        return fail_with("capacity", "No slots available on this load") if context.summary?

        seats = context.seats
        if context.create? && load.available_slots < seats
          return fail_with("capacity", "No slots available on this load")
        end

        load_vehicle = context.load_vehicle
        if load_vehicle && (context.create? || context.slot.load_vehicle_id_changed?) && load_vehicle.available_slots < seats
          return fail_with("capacity", "No slots available in #{load_vehicle.vehicle.name}", problem: "vehicle_capacity")
        end

        pass("capacity")
      end
    end
  end
end
