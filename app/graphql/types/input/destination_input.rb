# frozen_string_literal: true

module Types
  module Input
    class DestinationInput < Types::Base::Input
      argument :operator_id, Int, required: false
      argument :kind, Types::Operator::DestinationKind, required: false
      argument :name, String, required: false
      argument :altitude_m, Float, required: false
      argument :altitude_ft, Int, required: false, description: "Same as altitudeM, in feet; altitudeM wins when both are given"
      argument :location, GraphQL::Types::JSON, required: false
      argument :stops, GraphQL::Types::JSON, required: false
      argument :min_certification_rank, Int, required: false
    end
  end
end
