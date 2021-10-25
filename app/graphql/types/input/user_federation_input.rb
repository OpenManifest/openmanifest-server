# frozen_string_literal: true

module Types
  module Input
    class UserFederationInput < Types::BaseInputObject
      argument :federation_id, Integer, required: true
      argument :uid, String, required: false,
      description: "User Federation ID, e.g APF number"
      argument :license_id, Integer, required: false
    end
  end
end
