module Types
  class DropzoneUserType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :role, Types::UserRoleType, null: true
    def role
      object.user_role
    end
    field :expires_at, Int, null: true
    field :created_at, Int, null: false
    field :updated_at, Int, null: false
  end
end