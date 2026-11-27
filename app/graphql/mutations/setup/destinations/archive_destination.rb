# frozen_string_literal: true

module Mutations::Setup::Destinations
  # Archives rather than deletes: past slots and loads keep the destination they went to
  class ArchiveDestination < DestinationMutation
    argument :id, Int, required: true

    def resolve(id:)
      destination = ::Destination.kept.find(id)
      destination.discard ? saved(destination.reload) : refused(destination)
    rescue ActiveRecord::RecordNotFound => error
      { destination: nil, field_errors: nil, errors: [error.message] }
    end

    def authorized?(id: nil)
      permitted?(::Destination.find(id).operator_id, "You don't have permissions to archive destinations")
    end
  end
end
