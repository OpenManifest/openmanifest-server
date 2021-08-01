# frozen_string_literal: true

module Mutations
  class DeleteTicketType < Mutations::BaseMutation
    field :ticket_type, Types::TicketTypeType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :id, Int, required: true

    def resolve(id:)
      model = TicketType.find(id)

      # Flag as deleted if any slots use this ticket type
      if model.slots.empty?
        model.destroy
      else
        model.update(is_deleted: true)
      end

      {
        ticket_type: model,
        field_errors: nil,
        errors: nil
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        ticket_type: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotSaved => error
      # Failed save, return the errors to the client
      {
        ticket_type: nil,
        field_errors: nil,
        errors: error.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        ticket_type: nil,
        field_errors: nil,
        errors: [ error.message ]
      }
    end

    def authorized?(id: nil, attributes: nil)
      model = TicketType.find(id)

      if context[:current_resource].can?(
        :deleteTicketType,
        dropzone_id: model.dropzone_id
      )
        true
      else
        return false, {
          errors: ["You cannot remove tickets"]
          }
      end
    end
  end
end
