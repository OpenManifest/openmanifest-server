# frozen_string_literal: true

module Types::Operator
  # Where a load goes: an exit altitude, a dive site, a route or a river section (GENERALISATION §4)
  class Destination < Types::Base::Object
    graphql_name "Destination"
    implements Types::Interfaces::Polymorphic

    field :id, GraphQL::Types::ID, null: false
    field :kind, Types::Operator::DestinationKind, null: false
    field :name, String, null: false
    field :altitude_m, Float, null: true, description: "The height in metres (altitude destinations)"
    def altitude_m
      object.altitude_m&.to_f
    end
    field :altitude_ft, Int, null: true, description: "The height in whole feet, until units arrive with P7.12"
    field :location, GraphQL::Types::JSON, null: false, description: "lat, lng, max_depth_m, grade, ..."
    field :stops, GraphQL::Types::JSON, null: false, description: "The ordered stops of a route"
    field :min_certification_rank, Int, null: true
    field :discarded_at, GraphQL::Types::ISO8601DateTime, null: true
    async_field :operator, Types::OperatorType, null: false
    timestamp_fields
  end
end
