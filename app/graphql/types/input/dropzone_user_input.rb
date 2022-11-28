# frozen_string_literal: true

module Types
  module Input
    class DropzoneUserInput < Types::BaseInputObject
      argument :expires_at, Int, required: false
      argument :credits, Float, required: false
      argument :user_role_id, Int, required: false
      argument :name, String, required: false
      argument :nickname, String, required: false
      argument :push_token, String, required: false
      argument :image, String, required: false
      argument :federation_number, String, required: false
      argument :phone, String, required: false
      argument :email, String, required: false
      argument :license, Int, required: false,
                              prepare: -> (value, ctx) { License.find_by(id: value) }
      argument :exit_weight, Float, required: false
    end
  end
end
