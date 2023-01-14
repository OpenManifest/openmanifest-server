# frozen_string_literal: true

module Types::Dropzone
  class Aircraft < Types::Base::Object
    graphql_name 'Plane'
    implements Types::Interfaces::Polymorphic

    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    field :min_slots, Int, null: true
    field :max_slots, Int, null: false
    def max_slots
      object.max_slots || object.min_slots || 0
    end
    field :hours, Int, null: true
    field :next_maintenance_hours, Int, null: true
    field :registration, String, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :dropzone, Types::DropzoneType, null: false
  end
end
