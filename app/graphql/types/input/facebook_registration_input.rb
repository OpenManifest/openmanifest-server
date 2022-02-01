# frozen_string_literal: true

module Types
  module Input
    class FacebookRegistrationInput < Types::BaseInputObject
      argument :id, String, required: true
      argument :name, String, required: true
      argument :email, String, required: true
      argument :token, String, required: true
      argument :image_url, String, required: false
    end
  end
end
