# frozen_string_literal: true

module Types
  module Input
    class MembershipInput < Types::Base::Input
      argument :expires_at, Int, required: false
      money_argument :credits
      argument :user_role_id, Int, required: false
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
    end
  end
end
