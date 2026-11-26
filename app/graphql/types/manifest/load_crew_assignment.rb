# frozen_string_literal: true

module Types::Manifest
  # Who fills a crew role on a load, for the load or for one of its vehicles
  class LoadCrewAssignment < Types::Base::Object
    graphql_name "LoadCrewAssignment"
    implements Types::Interfaces::Polymorphic

    field :id, GraphQL::Types::ID, null: false
    async_field :crew_role, Types::Operator::CrewRole, null: false
    async_field :membership, Types::Users::Membership, null: false
    async_field :load_vehicle, Types::Manifest::LoadVehicle, null: true
  end
end
