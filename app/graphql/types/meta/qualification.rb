# frozen_string_literal: true

module Types::Meta
  class Qualification < Types::Base::Object
    implements Types::Interfaces::Polymorphic
    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
  end
end
