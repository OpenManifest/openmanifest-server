# frozen_string_literal: true

module Types
  module Input
    class SlotInput < Types::Base::Input
      argument :membership, GraphQL::Types::ID, required: false,
                                                prepare: -> (value, ctx) { ::Membership.find_by(id: value) }
      argument :ticket_type, GraphQL::Types::ID, required: false,
                                                 prepare: -> (value, ctx) { ::TicketType.find_by(id: value) }
      argument :activity_type, GraphQL::Types::ID, required: false,
                                                   prepare: -> (value, ctx) { ::ActivityType.find_by(id: value) }
      argument :destination, GraphQL::Types::ID, required: false,
                                                 prepare: -> (value, ctx) { ::Destination.kept.find_by(id: value) },
                                                 description: "Where this slot goes (per-slot destinations); the ticket type's by default"
      argument :load_vehicle, GraphQL::Types::ID, required: false,
                                                  prepare: -> (value, ctx) { ::LoadVehicle.find_by(id: value) },
                                                  description: "The vehicle of the load this slot rides in (loads with several vehicles that carry)"
      argument :load, GraphQL::Types::ID, required: false,
                                          prepare: -> (value, ctx) { ::Load.find_by(id: value) }
      argument :equipment, [GraphQL::Types::ID], required: false,
                                                 prepare: -> (value, ctx) { ::Equipment.where(id: value) },
                                                 description: "The items the slot uses: a rig, or a BCD, regulator and wetsuit"
      argument :body_mass_kg, Float, required: false
      argument :extras, [GraphQL::Types::ID], required: false,
                                              prepare: -> (value, ctx) { ::Extra.where(id: value) }

      argument :group_number, Int, required: false
      argument :user_group, [Types::Input::SlotUser], required: false

      argument :guest_name, String, required: false
      argument :guest_body_mass_kg, Float, required: false
      argument :lock_version, Int, required: false,
                                   description: "The lockVersion of the slot as the client last saw it; an older one is refused with CONFLICT"
    end
  end
end
