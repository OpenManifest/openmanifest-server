module Types
  class UserType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    field :email, String, null: true
    field :phone, String, null: true
    field :password, String, null: true
    field :password_digest, String, null: true
    field :created_at, Int, null: false
    field :updated_at, Int, null: false

    field :dropzone_users, [Types::DropzoneUserType], null: true
  end
end