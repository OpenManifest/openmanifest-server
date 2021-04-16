# frozen_string_literal: true

module Types
  module Input
    class UserInput < Types::BaseInputObject
      argument :name, String, required: false
      argument :nickname, String, required: false
      argument :image, String, required: false
      argument :phone, String, required: false
      argument :email, String, required: false
    end
  end
end
