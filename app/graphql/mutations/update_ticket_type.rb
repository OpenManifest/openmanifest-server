# frozen_string_literal: true

module Mutations
  class UpdateTicketType < Mutations::BaseMutation
    field :ticket_type, Types::TicketTypeType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :id, Int, required: true
    argument :attributes, Types::Input::TicketTypeInput, required: true

    def resolve(attributes:, id:)
      model = TicketType.find(id)

      model.update!(attributes.to_h)
      unless attributes[:extra_ids].nil?
        ::TicketTypeExtra.includes(:extra, :ticket_type).where(
          extras: { dropzone_id: attributes[:dropzone_id] }
        ).where.not(
          extras: { id: attributes[:extra_ids] }
        ).destroy_all

        attributes[:extra_ids] - TicketTypeExtra.where(
          extra_id: attributes[:extra_ids]
        ).pluck(:extra_id).to_a do |i|
          ::TicketTypeExtra.create(extra_id: i, ticket_type: model)
        end
      end

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
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotSaved => invalid
      # Failed save, return the errors to the client
      {
        ticket_type: nil,
        field_errors: nil,
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        ticket_type: nil,
        field_errors: nil,
        errors: [ error.message ]
      }
    end

    def authorized?(id: nil, attributes: nil)
      if context[:current_resource].can?(
        "updateTicketType",
        dropzone_id: TicketType.find(id).dropzone_id
      )
        true
      else
        return false, {
        errors: [
          "You don't have permissions to update ticket types"
          ]
        }
      end
    end
  end
end
