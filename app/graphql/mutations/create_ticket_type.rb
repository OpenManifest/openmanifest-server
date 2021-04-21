# frozen_string_literal: true

module Mutations
  class CreateTicketType < Mutations::BaseMutation
    field :ticket_type, Types::TicketTypeType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true


    argument :attributes, Types::Input::TicketTypeInput, required: true

    def resolve(attributes:)
      model = TicketType.new(attributes.to_h.except("extra_ids"))

      model.save!
      unless attributes[:ticket_type_ids].nil?
        ::TicketTypeExtra.create(
          Extra.where(id: attributes[:ticket_type_ids]).map do |e|
            { extra_id: e.id, ticket_type_id: model.id }
          end
        )
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

    def authorized?(attributes: nil)
      if context[:current_resource].can?(
        "createTicketType",
        dropzone_id: attributes[:dropzone_id]
      )
        return true
      else
        return false, {
          errors: [
            "You don't have permissions to create ticket addons"
            ]
          }
      end
    end
  end
end
