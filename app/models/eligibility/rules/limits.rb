# frozen_string_literal: true

module Eligibility
  module Rules
    # Who the ticket and the activity take (the `limits` module): a minimum and maximum age and body mass of each person who
    # rides (the member, and the guests of an escort), the body mass and size of a flight group, and what the vehicles of the
    # load can carry. Age needs a date of birth; a limit with no date of birth to check against fails with its own problem.
    class Limits < Rule
      self.bypass_permission = :createUserSlot

      def applies?(operator) = operator.module?(:limits)

      def check(context)
        operator = context.operator
        return check_member(context) if context.summary?
        # A guest of an escort is looked at with the escort; a guest of their own (a booking) with the limits of the ticket
        return if context.slot.escort_slot_id || context.slot.escort_slot || (context.membership.nil? && context.guest.nil?)

        limits = participant_limits(context)
        [
          (age(context, limits) if module_flag?(operator, :limits, :age)),
          (body_mass(context, limits) if module_flag?(operator, :limits, :mass)),
          (group(context) if module_flag?(operator, :limits, :mass)),
          (payload(context) if module_flag?(operator, :limits, :payload)),
        ].compact
      end

      # The stricter of the ticket's limits and the activity's
      def participant_limits(context)
        both = [context.ticket_type&.participant_limits, context.activity_type&.participant_limits].compact
        both.each_with_object({}) do |limits, merged|
          limits.each do |key, value|
            next if value.nil?

            merged[key] = if merged.key?(key)
                            key.start_with?("min_") ? [merged[key], value].max : [merged[key], value].min
                          else
                            value
                          end
          end
        end
      end

      private

      # Everyone who rides: the member, then each guest, with the date of birth and body mass the slot has for them
      def riders(context)
        member = context.user
        people = if member
                   [{ name: member.name, date_of_birth: member.date_of_birth, body_mass_kg: context.body_mass_kg }]
                 else
                   [{ name: context.guest&.name.presence || "A guest", date_of_birth: context.guest&.date_of_birth, body_mass_kg: context.slot.body_mass_kg || context.guest&.body_mass_kg }]
                 end
        people + context.guest_slots.map do |guest_slot|
          guest = guest_slot.guest
          { name: guest&.name.presence || "A guest", date_of_birth: guest&.date_of_birth, body_mass_kg: guest_slot.body_mass_kg || guest&.body_mass_kg }
        end
      end

      def age(context, limits)
        min = limits["min_age"]
        max = limits["max_age"]
        return pass("age") if min.nil? && max.nil?

        problems = riders(context).filter_map do |rider|
          dob = rider[:date_of_birth]
          next [:date_of_birth_missing, "#{rider[:name]}'s date of birth is needed"] if dob.nil?

          years = age_on(dob, context.date)
          next [:age, "#{rider[:name]} must be at least #{min} years old"] if min && years < min
          next [:age, "#{rider[:name]} must be at most #{max} years old"] if max && years > max
        end
        return pass("age") if problems.empty?

        fail_with("age", problems.map(&:last).join(", "), problem: problems.first.first.to_s)
      end

      def body_mass(context, limits)
        min = limits["min_body_mass_kg"]
        max = limits["max_body_mass_kg"]
        return pass("body_mass") if min.nil? && max.nil?

        problems = riders(context).filter_map do |rider|
          mass = rider[:body_mass_kg]
          next [:body_mass_missing, "#{rider[:name]}'s body mass is needed"] if mass.nil? || mass.zero?
          next [:body_mass, "#{rider[:name]} must weigh at least #{format_mass(min)}"] if min && mass < min
          next [:body_mass, "#{rider[:name]} must weigh at most #{format_mass(max)}"] if max && mass > max
        end
        return pass("body_mass") if problems.empty?

        fail_with("body_mass", problems.map(&:last).join(", "), problem: problems.first.first.to_s)
      end

      # Slots with the same group number on the load are one flight group; a person's guests fly with them
      def group(context)
        limits = context.ticket_type&.group_limits || {}
        max_mass = limits["max_group_body_mass_kg"]
        max_size = limits["max_group_size"]
        number = context.group_number.to_i
        return if number.zero? || (max_mass.nil? && max_size.nil?)

        others = ::Slot.where(load_id: context.load.id).includes(:guest_slots).reject { |slot| context.slot.persisted? && (slot.id == context.slot.id || slot.escort_slot_id == context.slot.id) }
        others = others.select { |slot| slot.group_number == number && slot.escort_slot_id.nil? }
        people = others.size + others.sum { |slot| slot.guest_slots.size } + context.seats
        mass = others.sum { |slot| slot.body_mass_kg.to_f + slot.guest_slots.sum { |guest_slot| guest_slot.body_mass_kg.to_f } }
        mass += riders(context).sum { |rider| rider[:body_mass_kg].to_f }

        return fail_with("group", "A flight group takes at most #{max_size} people", problem: "group_size") if max_size && people > max_size
        return fail_with("group", "A flight group can weigh at most #{format_mass(max_mass)}", problem: "group_mass") if max_mass && mass > max_mass

        pass("group")
      end

      # The load, and the vehicle the slot rides in, stay under what they may carry
      def payload(context)
        load = context.load
        return unless load

        carrying = load.carrying_load_vehicles
        vehicle = context.load_vehicle
        mass = riders(context).sum { |rider| rider[:body_mass_kg].to_f }

        if vehicle&.vehicle&.max_payload_kg
          carried = ::Slot.where(load_id: load.id).reject { |slot| context.slot.persisted? && (slot.id == context.slot.id || slot.escort_slot_id == context.slot.id) }.select { |slot| slot.load_vehicle_id == vehicle.id }
          if carried.sum { |slot| slot.body_mass_kg.to_f } + mass > vehicle.vehicle.max_payload_kg
            return fail_with("payload", "#{vehicle.vehicle.name} can carry at most #{format_mass(vehicle.vehicle.max_payload_kg)}", problem: "vehicle_payload")
          end
        end

        return unless carrying.any? && carrying.all? { |row| row.vehicle.max_payload_kg }

        limit = carrying.sum { |row| row.vehicle.max_payload_kg }
        total = load.mass_kg(except: context.slot) + mass
        return fail_with("payload", "The load can carry at most #{format_mass(limit)}", problem: "load_payload") if total > limit

        pass("payload")
      end

      # The member's part of it: a body mass and, when a ticket or an activity has an age limit, a date of birth
      def check_member(context)
        operator = context.operator
        user = context.user
        [
          (member_body_mass(user) if module_flag?(operator, :limits, :mass)),
          (member_date_of_birth(operator, user) if module_flag?(operator, :limits, :age)),
        ].compact
      end

      def member_body_mass(user)
        return pass("body_mass") if user.body_mass_kg.present?

        fail_with("body_mass", "#{user.name} has no exit weight on their profile", problem: "body_mass_missing")
      end

      def member_date_of_birth(operator, user)
        return not_required("age") unless operator.age_limited?
        return pass("age") if user.date_of_birth.present?

        fail_with("age", "#{user.name} has no date of birth on their profile", problem: "date_of_birth_missing")
      end

      def age_on(date_of_birth, date)
        age = date.year - date_of_birth.year
        age -= 1 if date < date_of_birth + age.years
        age
      end

      def format_mass(kg) = "#{kg.to_f.round(1).to_s.delete_suffix('.0')} kg"
    end
  end
end
