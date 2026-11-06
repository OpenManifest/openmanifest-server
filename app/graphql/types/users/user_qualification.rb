# frozen_string_literal: true

module Types::Users
  class UserQualification < Types::Base::Object
    implements Types::Interfaces::Polymorphic
    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    field :expires_at, GraphQL::Types::ISO8601DateTime, null: true, description: "Empty for a qualification that does not expire"
    field :number, String, null: true
    field :verified_at, GraphQL::Types::ISO8601DateTime, null: true
    field :current, Boolean, null: false, method: :current?, description: "False once the qualification has expired"
    async_field :qualification, Types::Meta::Qualification, null: false
  end
end
