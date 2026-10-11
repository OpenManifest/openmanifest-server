# frozen_string_literal: true

module Mutations::Setup::Tickets
  class UpdateExtra < Mutations::BaseMutation
    field :errors, [String], null: true
    field :extra, Types::Dropzone::Tickets::Addon, null: true
    field :field_errors, [Types::System::FieldError], null: true

    argument :attributes, Types::Input::ExtraInput, required: true
    argument :id, Int, required: false

    def resolve(attributes:, id: nil)
      model = Extra.find(id)

      # An add-on never moves to another dropzone, and only this dropzone's ticket types can be linked to it
      attrs = attributes.to_h.except(:dropzone_id, :ticket_type_ids)
      attrs[:ticket_type_ids] = model.dropzone.ticket_types.where(id: attributes[:ticket_type_ids]).pluck(:id) unless attributes[:ticket_type_ids].nil?
      model.update!(attrs)

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

    # The add-on's own dropzone decides. The id stays optional in the schema (the client's document declares it
    # nullable) but updating needs one.
    def authorized?(id: nil, attributes: nil)
      extra = Extra.find_by(id: id)
      return [false, { errors: ["Ticket add-on not found"] }] unless extra

      if context[:current_resource].can?("updateExtra", dropzone_id: extra.dropzone_id)
        true
      else
        [
          false, {
            errors: [
              "You don't have permissions to update ticket addons",
            ],
          },
        ]
      end
    end
  end
end
