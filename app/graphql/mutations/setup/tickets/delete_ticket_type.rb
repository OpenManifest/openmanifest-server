# frozen_string_literal: true

module Mutations::Setup::Tickets
  class DeleteTicketType < Mutations::BaseMutation
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true
    field :ticket_type, Types::TicketTypeType, null: true

    argument :id, Int, required: true

    def resolve(id:)
      model = TicketType.find(id)

      # Flag as deleted if any slots use this ticket type
      if model.slots.empty?
        model.destroy
      else
        model.discard
      end

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
      dz_user = Dropzone.find(id).dropzone_users.find_by(user_id: context[:current_user])
      if dz_user.can? :deleteDropzone
        true
      else
        [
          false, {
            errors: ["You cant delete this dropzone"],
          },
        ]
      end
    end
  end
end
