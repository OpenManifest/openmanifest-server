# frozen_string_literal: true

module Mutations::Manifest
  class CreateLoad < Mutations::BaseMutation
    field :load, Types::LoadType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :attributes, Types::Input::LoadInput, required: true

    def resolve(attributes:)
      model = Load.new(attributes.to_h)

      model.save!

      Event.create(
        level: :info,
        resource: model,
        action: :created,
        message: "#{context[:current_resource].name} created Load ##{model.load_number}",
        dropzone_id: attributes[:dropzone_id],
        dropzone_user: DropzoneUser.find_by(
          dropzone_id: attributes[:dropzone_id],
          user_id: context[:current_resource].id
        )
      )
      {
        load: model,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        load: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotSaved => invalid
      # Failed save, return the errors to the client
      {
        load: nil,
        field_errors: nil,
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        load: nil,
        field_errors: nil,
        errors: [ error.message ]
      }
    end

    def authorized?(attributes: nil)
      if context[:current_resource].can?(
        "createLoad",
        dropzone_id: Plane.find(attributes[:plane_id]).dropzone.id
      )
        true
      else
        return false, {
          errors: [
            "You don't have permissions to create loads"
            ]
          }
      end
    end
  end
end
