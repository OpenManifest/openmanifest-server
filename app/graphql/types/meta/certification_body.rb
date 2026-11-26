# frozen_string_literal: true

module Types::Meta
  class CertificationBody < Types::Base::Object
    field :id, GraphQL::Types::ID, null: false
    async_field :certification_levels, [Types::Meta::CertificationLevel], null: true
    async_field :qualifications, [Types::Meta::Qualification], null: true
    field :name, String, null: true
    field :slug, String, null: true
    field :industry, String, null: true
    field :verification_provider, String, null: true, description: "Who checks a member's number against the body's records; none means staff verify by hand"
    timestamp_fields
  end
end
