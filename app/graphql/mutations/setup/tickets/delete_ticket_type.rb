# frozen_string_literal: true

module Mutations::Setup::Tickets
  class DeleteTicketType < Mutations::BaseMutation
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true
    field :ticket_type, Types::Dropzone::Ticket, null: true

    argument :id, Int, required: true

    def resolve(id:)
      model = TicketType.find(id)

      # Archive rather than destroy: the mutation is called archiveTicketType and past orders and slots keep pointing at it
      model.discard

      {
        ticket_type: model.reload,
        field_errors: nil,
        errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        ticket_type: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotSaved => error
      # Failed save, return the errors to the client
      {
        ticket_type: nil,
        field_errors: nil,
        errors: error.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        ticket_type: nil,
        field_errors: nil,
        errors: [error.message],
      }
    end

    def authorized?(id: nil, attributes: nil)
      ticket_type = TicketType.find_by(id: id)
      return [false, { errors: ["Ticket type not found"] }] unless ticket_type

      if context[:current_resource].can?(:deleteTicketType, dropzone_id: ticket_type.dropzone_id)
        true
      else
        [
          false, {
            errors: ["You can't delete this ticket type"],
          },
        ]
      end
    end
  end
end
