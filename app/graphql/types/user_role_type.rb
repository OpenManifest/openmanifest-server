module Types
  class UserRoleType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    field :created_at, Int, null: false
    field :updated_at, Int, null: false
    field :dropzone_id, Int, null: false
    field :dropzone, Types::DropzoneType, null: false

    field :permissions, [String], null: false
    def permissions
      object.permissions.map(&:name)
    end
  end
end