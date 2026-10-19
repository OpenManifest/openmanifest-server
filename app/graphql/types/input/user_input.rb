# frozen_string_literal: true

module Types
  module Input
    class UserInput < Types::Base::Input
      argument :name, String, required: false
      argument :nickname, String, required: false
      argument :push_token, String, required: false
      argument :image, String, required: false
      argument :certification_body_number, String, required: false
      argument :phone, String, required: false
      argument :email, String, required: false
      argument :certification_level, Int, required: false,
                                          prepare: -> (value, ctx) { CertificationLevel.find_by(id: value) }
      argument :body_mass_kg, Float, required: false
      argument :date_of_birth, GraphQL::Types::ISO8601Date, required: false
    end
  end
end
