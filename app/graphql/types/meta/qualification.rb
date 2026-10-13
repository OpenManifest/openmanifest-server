# frozen_string_literal: true

module Types::Meta
  class Qualification < Types::Base::Object
    implements Types::Interfaces::Polymorphic
    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    field :slug, String, null: true
    async_field :certification_body, Types::Meta::CertificationBody, null: false
  end
end
