module Types
  class PlaneType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    field :min_slots, Int, null: true
    field :max_slots, Int, null: true
    field :hours, Int, null: true
    field :next_maintenance_hours, Int, null: true
    field :registration, String, null: true
    field :created_at, Int, null: false
    field :updated_at, Int, null: false
    field :dropzone, Types::DropzoneType, null: false
  end
end