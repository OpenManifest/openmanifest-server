# frozen_string_literal: true

module Types::Operator
  # A job on a load: pilot, GCA, skipper, guide (GENERALISATION §7)
  class CrewRole < Types::Base::Object
    graphql_name "CrewRole"
    implements Types::Interfaces::Polymorphic

    field :id, GraphQL::Types::ID, null: false
    field :key, String, null: false
    field :name, String, null: false
    field :scope, Types::Operator::CrewRoleScope, null: false, description: "load: filled once per load; vehicle: once per vehicle it applies to"
    field :required, Boolean, null: false
    field :occupies_slot, Boolean, null: false, description: "The crew member takes a seat of the vehicle"
    field :permission, String, null: true, description: "What a member needs to fill the role"
    field :vehicle_kinds, [String], null: false, description: "A role per vehicle applies to these kinds of vehicle; none: to every vehicle that carries"
    field :position, Int, null: false
    field :discarded_at, GraphQL::Types::ISO8601DateTime, null: true
    timestamp_fields
  end
end
