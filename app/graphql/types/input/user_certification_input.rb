# frozen_string_literal: true

module Types
  module Input
    class UserCertificationInput < Types::Base::Input
      argument :certification_body, GraphQL::Types::ID, required: true,
                                                        prepare: -> (value, ctx) { ::CertificationBody.find_by(id: value) }
      argument :uid, String, required: false,
                             description: "The member's id at the body, e.g APF number"
      argument :number, String, required: false,
                                description: "The number on the certificate of the level"
      argument :certification_level, GraphQL::Types::ID, required: false,
                                                         prepare: -> (value, ctx) { ::CertificationLevel.find_by(id: value) }
    end
  end
end
