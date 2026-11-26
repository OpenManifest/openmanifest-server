# frozen_string_literal: true

module Types
  module Input
    # Somebody who rides with an escort, with the personal fields of a booking participant
    class GuestInput < Types::Base::Input
      argument :name, String, required: false
      argument :body_mass_kg, Float, required: false
      argument :email, String, required: false
      argument :phone, String, required: false
      argument :date_of_birth, GraphQL::Types::ISO8601Date, required: false
      argument :emergency_contact, String, required: false
    end
  end
end
