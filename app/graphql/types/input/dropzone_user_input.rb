# frozen_string_literal: true

module Types
  module Input
    class DropzoneUserInput < Types::BaseInputObject
      argument :expires_at, Int, required: false
      argument :credits, Float, required: false
      argument :user_role_id, Int, required: false
    end
  end
end
