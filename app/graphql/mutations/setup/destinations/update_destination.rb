# frozen_string_literal: true

module Mutations::Setup::Destinations
  class UpdateDestination < DestinationMutation
    argument :attributes, Types::Input::DestinationInput, required: true
    argument :id, Int, required: true

    def resolve(attributes:, id:)
      destination = ::Destination.kept.find(id)
      destination.update(attributes_for(attributes)) ? saved(destination) : refused(destination)
    rescue ActiveRecord::RecordNotFound => error
      { destination: nil, field_errors: nil, errors: [error.message] }
    end

    def authorized?(id: nil, attributes: nil)
      permitted?(::Destination.find(id).operator_id, "You don't have permissions to update destinations")
    end
  end
end
