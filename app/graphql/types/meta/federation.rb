# frozen_string_literal: true

module Types::Meta
  class Federation < Types::Base::Object
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :id, GraphQL::Types::ID, null: false
    field :licenses, [Types::Meta::License], null: true
    field :name, String, null: true
    field :slug, String, null: true
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
