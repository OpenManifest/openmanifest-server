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
      argument :load, GraphQL::Types::ID, required: false,
                                          prepare: -> (value, ctx) { ::Load.find_by(id: value) }
      argument :rig, GraphQL::Types::ID, required: false,
                                         prepare: -> (value, ctx) { ::Rig.find_by(id: value) }
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
