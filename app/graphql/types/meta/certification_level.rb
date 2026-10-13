# frozen_string_literal: true

module Types::Meta
  class CertificationLevel < Types::Base::Object
    implements Types::Interfaces::Polymorphic
    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    field :rank, Int, null: false, description: "Comparable across bodies of an industry: a higher rank is a higher level"
    field :equivalence_key, String, null: true, description: "Levels of different bodies with the same key count as the same tier"
    async_field :certification_body, Types::Meta::CertificationBody, null: true
    timestamp_fields
  end
end
