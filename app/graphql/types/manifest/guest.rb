# frozen_string_literal: true

module Types::Manifest
  # Somebody who rides with an escort (skydiving: the tandem passenger)
  class Guest < Types::Base::Object
    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    field :body_mass_kg, Float, null: true
    field :email, String, null: true
    field :phone, String, null: true
    field :date_of_birth, GraphQL::Types::ISO8601Date, null: true
    field :emergency_contact, String, null: true
  end
end
