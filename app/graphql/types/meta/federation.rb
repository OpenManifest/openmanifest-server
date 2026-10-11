# frozen_string_literal: true

module Types::Meta
  class Federation < Types::Base::Object
    field :id, GraphQL::Types::ID, null: false
    async_field :licenses, [Types::Meta::License], null: true
    field :name, String, null: true
    field :slug, String, null: true
    timestamp_fields
  end
end
