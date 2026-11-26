# frozen_string_literal: true

module Types::Users
  class UserCertification < Types::Base::Object
    implements Types::Interfaces::Polymorphic
    field :id, GraphQL::Types::ID, null: false
    field :uid, String, null: true,
                        description: "The member's id at the body, e.g APF number"
    field :number, String, null: true, description: "The number on the certificate of the level"
    field :verified_at, GraphQL::Types::ISO8601DateTime, null: true
    async_field :certification_body, Types::Meta::CertificationBody, null: false
    async_field :certification_level, Types::Meta::CertificationLevel, null: true
    async_field :user, Types::Users::User, null: false
    field :qualifications, [Types::Users::UserQualification], null: true
    def qualifications
      object.user_qualifications
    end
  end
end
