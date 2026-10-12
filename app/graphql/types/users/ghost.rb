# frozen_string_literal: true

module Types::Users
  class Ghost < Types::Base::Object
    field :email, String, null: true
    field :body_mass_kg, Integer, null: true
    field :id, GraphQL::Types::ID, null: false
    field :license, Types::Meta::License, null: true
    field :memberships, [Types::Users::Membership], null: true
    field :phone, String, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :activity_types, [Types::Meta::ActivityType], null: true
    field :updated_at, Integer, null: false
  end
end
