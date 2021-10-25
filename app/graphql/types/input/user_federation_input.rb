# frozen_string_literal: true

module Types
  module Input
    class UserFederationInput < Types::BaseInputObject
      argument :federation_id, Integer, required: true
      argument :uid, Integer, required: false,
      description: 'User Federation ID, e.g APF number'
    end
  end
end
