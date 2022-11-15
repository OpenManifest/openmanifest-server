# frozen_string_literal: true

module Mutations::Setup::Tickets
  class UpdateExtra < Mutations::BaseMutation
    field :errors, [String], null: true
    field :extra, Types::ExtraType, null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :attributes, Types::Input::ExtraInput, required: true
    argument :id, Int, required: false

    def resolve(attributes:, id: nil)
      model = find_or_build_model(id)
      model.attributes = attributes.to_h.except("ticket_type_ids")

      model.save!
      unless attributes[:ticket_type_ids].nil?
        ::TicketTypeExtra.includes(:extra, :ticket_type).where(
          ticket_types: { dropzone_id: attributes[:dropzone_id] }
        ).where.not(
          ticket_types: { id: attributes[:ticket_type_ids] }
        ).destroy_all

        attributes[:ticket_type_ids] - TicketTypeExtra.where(
          ticket_type_id: attributes[:ticket_type_ids]
        ).pluck(:ticket_type_id).to_a do |i|
          ::TicketTypeExtra.create(extra: model, ticket_type_id: i)
        end
      end

      {
        extra: model,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        extra: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotSaved => invalid
      # Failed save, return the errors to the client
      {
        extra: nil,
        field_errors: nil,
        errors: invalid.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        extra: nil,
        field_errors: nil,
        errors: [error.message],
      }
    end

    def authorized?(id: nil, attributes: nil)
      if context[:current_resource].can?(
        "updateExtra",
        dropzone_id: Extra.find(id).dropzone_id
      )
        true
      else
        [
          false, {
            errors: [
              "You don't have permissions to create ticket addons",
            ],
          },
        ]
      end
    end

    def find_or_build_model(id)
      if id
        Extra.find(id)
      else
        Extra.new
      end
    end
  end
end
