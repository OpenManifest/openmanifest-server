# frozen_string_literal: true

module Mutations::Setup::Destinations
  # What createDestination, updateDestination and archiveDestination share: the payload, the permission (updateOperator,
  # like the rest of the operator's setup) and the answer to a record that does not save
  class DestinationMutation < Mutations::BaseMutation
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true
    field :destination, Types::Operator::Destination, null: true

    private

    def attributes_for(attributes)
      attrs = attributes.to_h.except(:operator_id)
      feet = attrs.delete(:altitude_ft)
      attrs[:altitude_m] = (feet * ::Destination::FEET).round(2) if feet && attrs[:altitude_m].nil?
      attrs
    end

    def saved(destination)
      { destination: destination, errors: nil, field_errors: nil }
    end

    def refused(destination)
      {
        destination: nil,
        field_errors: destination.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: destination.errors.full_messages,
      }
    end

    def permitted?(operator_id, message)
      return true if context[:current_resource].can?("updateOperator", operator_id: operator_id)

      [false, { errors: [message] }]
    end
  end
end
