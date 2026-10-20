# frozen_string_literal: true

# Would this slot be allowed, and which rules say what? The same rules that stop a slot being saved, run on a slot built
# from the arguments and not saved (P7.16).
class Resolvers::Manifest::SlotEligibility < Resolvers::Base
  description "The result of every eligibility rule for a slot that is about to be manifested"
  type [Types::Manifest::EligibilityResult], null: false

  argument :load_id, GraphQL::Types::ID, required: true
  argument :membership_id, GraphQL::Types::ID, required: false, description: "The member to manifest; or a guest"
  argument :guest, Types::Input::GuestInput, required: false, description: "Somebody who is not a member (a booking)"
  argument :ticket_type_id, GraphQL::Types::ID, required: true
  argument :activity_type_id, GraphQL::Types::ID, required: false
  argument :extra_ids, [GraphQL::Types::ID], required: false
  argument :equipment_ids, [GraphQL::Types::ID], required: false
  argument :load_vehicle_id, GraphQL::Types::ID, required: false
  argument :group_number, Int, required: false
  argument :body_mass_kg, Float, required: false
  argument :guests, [Types::Input::GuestInput], required: false, description: "The guests who ride with the member, on a ticket type that requires an escort"

  def resolve(load_id:, ticket_type_id:, membership_id: nil, guest: nil, activity_type_id: nil, extra_ids: nil, equipment_ids: nil,
              load_vehicle_id: nil, group_number: nil, body_mass_kg: nil, guests: nil)
    load = ::Load.kept.find_by(id: load_id)
    caller = authorize_record!(load)
    raise forbidden("You do not have permission to manifest") unless caller.nil? || caller.can?(:createSlot) || caller.can?(:createUserSlot)

    operator = load.operator
    member = operator.memberships.kept.find_by(id: membership_id) if membership_id
    ticket = operator.ticket_types.find_by(id: ticket_type_id)
    raise forbidden("The member, the ticket and the load must belong to the same operator") if ticket.nil? || (membership_id && member.nil?)
    raise GraphQL::ExecutionError, "Choose a member or a guest" if member.nil? && guest.nil?

    Eligibility.check(Eligibility::Context.new(build_slot(load, member, guest, ticket, caller, activity_type_id, extra_ids, equipment_ids,
                                                          load_vehicle_id, group_number, body_mass_kg, guests)), scopes: %i(slot manifest))
  end

  private

  def build_slot(load, member, guest, ticket, caller, activity_type_id, extra_ids, equipment_ids, load_vehicle_id, group_number, body_mass_kg, guests)
    slot = ::Slot.new(load: load, membership: member, ticket_type: ticket, created_by: caller, body_mass_kg: body_mass_kg,
                      group_number: group_number || 0, activity_type: (::ActivityType.find_by(id: activity_type_id) if activity_type_id),
                      load_vehicle: (load.load_vehicles.find_by(id: load_vehicle_id) if load_vehicle_id))
    slot.guest = ::Guest.new(guest.to_h.merge(operator: load.operator)) if guest
    slot.extras = ticket.extras.where(id: extra_ids) if extra_ids
    slot.equipment = ::Equipment.kept.where(id: equipment_ids) if equipment_ids
    guests.to_a.each do |attributes|
      slot.guest_slots.build(load: load, ticket_type: ticket, body_mass_kg: attributes[:body_mass_kg], guest: ::Guest.new(attributes.to_h.merge(operator: load.operator)))
    end
    slot
  end
end
