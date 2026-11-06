# frozen_string_literal: true

module Mutations::Setup::Destinations
  class CreateDestination < DestinationMutation
    argument :attributes, Types::Input::DestinationInput, required: true

    def resolve(attributes:)
      destination = ::Operator.find(attributes[:operator_id]).destinations.new(attributes_for(attributes))
      destination.save ? saved(destination) : refused(destination)
    rescue ActiveRecord::RecordNotFound => error
      { destination: nil, field_errors: nil, errors: [error.message] }
    end

    def authorized?(attributes: nil)
      permitted?(attributes[:operator_id], "You don't have permissions to create destinations")
    end
  end
end
