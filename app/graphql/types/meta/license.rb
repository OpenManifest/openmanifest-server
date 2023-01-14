# frozen_string_literal: true

module Types::Meta
  class License < Types::Base::Object
    implements Types::Interfaces::Polymorphic
    lookahead do |query|
      query = query.includes(:federation) if selects?(:federation)
      query
    end
    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    async_field :federation, Types::Meta::Federation, null: true
    timestamp_fields
  end
end
