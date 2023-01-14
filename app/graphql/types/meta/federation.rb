# frozen_string_literal: true

module Types::Meta
  class Federation < Types::Base::Object
    lookahead do |query|
      query = query.includes(:licenses) if selects?(:licenses)
      query
    end
    field :id, GraphQL::Types::ID, null: false
    field :licenses, [Types::Meta::License], null: true
    field :name, String, null: true
    field :slug, String, null: true
    timestamp_fields
  end
end
