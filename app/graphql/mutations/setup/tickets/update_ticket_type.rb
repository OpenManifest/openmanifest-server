# frozen_string_literal: true

module Mutations::Setup::Tickets
  class UpdateTicketType < Mutations::BaseMutation
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true
    field :ticket_type, Types::Dropzone::Ticket, null: true

    argument :attributes, Types::Input::TicketTypeInput, required: true
    argument :id, Int, required: true

    def resolve(attributes:, id:)
      model = TicketType.find(id)

      # A ticket type never moves to another dropzone, and only this dropzone's add-ons can be linked to it
      attrs = attributes.to_h.except(:dropzone_id, :extra_ids)
      attrs[:extra_ids] = model.dropzone.extras.where(id: attributes[:extra_ids]).pluck(:id) unless attributes[:extra_ids].nil?
      model.update!(attrs)

      {
        ticket_type: model,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        ticket_type: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotSaved => invalid
      # Failed save, return the errors to the client
      {
        ticket_type: nil,
        field_errors: nil,
        errors: invalid.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        ticket_type: nil,
        field_errors: nil,
        errors: [error.message],
      }
    end

    def authorized?(id: nil, attributes: nil)
      if context[:current_resource].can?(
        "updateTicketType",
        dropzone_id: TicketType.find(id).dropzone_id
      )
        true
      else
        [
          false, {
            errors: [
              "You don't have permissions to update ticket types",
            ],
          },
        ]
      end
    end
  end
end
