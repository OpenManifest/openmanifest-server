# frozen_string_literal: true

module Mutations::Setup::Aircrafts
  class CreatePlane < Mutations::BaseMutation
    field :plane, Types::PlaneType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :attributes, Types::Input::PlaneInput, required: true

    def resolve(attributes:)
      model = Plane.new(attributes.to_h)

      model.save!

      Event.create(
        level: :info,
        dropzone_id: attributes[:dropzone_id],
        action: :created,
        resource: model,
        message: "#{context[:current_resource].name} created a new aircraft '#{model.name}'",
        dropzone_user: DropzoneUser.find_by(
          dropzone_id: attributes[:dropzone_id],
          user_id: context[:current_user].id
        )
      )

      {
        plane: model,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        plane: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotSaved => invalid
      # Failed save, return the errors to the client
      {
        plane: nil,
        field_errors: nil,
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        plane: nil,
        field_errors: nil,
        errors: [ error.message ]
      }
    end

    def authorized?(attributes: nil)
      if context[:current_resource].can?(
        "createPlane",
        dropzone_id: attributes[:dropzone_id]
      )
        true
      else
        return false, {
          errors: [
            "You don't have permissions to create planes"
            ]
          }
      end
    end
  end
end
