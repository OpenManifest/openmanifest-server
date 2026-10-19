# frozen_string_literal: true

module Types::Operator
  class Vehicle < Types::Base::Object
    graphql_name 'Vehicle'
    implements Types::Interfaces::Polymorphic
    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    field :kind, String, null: true, description: "aircraft, raft, bus, ...: what crew roles per vehicle apply to"
    field :min_capacity, Int, null: true
    field :capacity, Int, null: false
    def capacity
      object.capacity || object.min_capacity || 0
    end
    field :max_payload_kg, Float, null: true, description: "What the vehicle may carry (the limits module)"
    field :hours, Int, null: true
    field :next_maintenance_hours, Int, null: true
    field :registration, String, null: true
    async_field :operator, Types::OperatorType, null: false
    timestamp_fields
  end
end
