# frozen_string_literal: true

module Types
  module Input
    class UserFederationInput < Types::BaseInputObject
      argument :federation, Integer, required: true,
               prepare: -> (value, ctx) { Federation.find_by(id: value) }
      argument :uid, String, required: false,
               description: "User Federation ID, e.g APF number"
      argument :license, Integer, required: false,
               prepare: -> (value, ctx) { License.find_by(id: value) }
    end
  end
end
