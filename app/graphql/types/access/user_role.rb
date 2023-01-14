# frozen_string_literal: true

module Types::Access
  class UserRole < Types::Base::Object
    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :dropzone_id, Int, null: false
    field :dropzone, Types::DropzoneType, null: false

    field :permissions, [String], null: false
    def permissions
      object.permissions.pluck(:name)
    end
  end
end
