# frozen_string_literal: true

module Mutations
  class CreateDropzone < Mutations::BaseMutation
    field :dropzone, Types::DropzoneType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :attributes, Types::Input::DropzoneInput, required: true

    def resolve(attributes:)
      model = Dropzone.new(attributes.to_h.except(:banner))

      model.save!
      if attributes[:banner] && attributes[:banner].size > 0
        model.banner.attach(data: attributes[:banner].force_encoding("UTF-8"))
      end

      ## Make current user owner
      DropzoneUser.create(
        dropzone: model,
        user: context[:current_resource],
        user_role: UserRole.find_by(dropzone_id: model.id, name: "owner")
      )



      ## Set up default rig inspection checklist
      {
        dropzone: model,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        dropzone: nil,
        field_errors: invalid.record.errors.messages,
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotSaved => error
      # Failed save, return the errors to the client
      {
        dropzone: nil,
        field_errors: nil,
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        dropzone: nil,
        field_errors: nil,
        errors: [ error.message ]
      }
    end

    def authorized?
      true
    end
  end
end
