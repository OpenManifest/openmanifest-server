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

      model.rig_inspection_template = FormTemplate.create(
        name: "Rig Inspection",
        definition: RigInspection.default_form.to_json,
        created_by: context[:current_resource],
        updated_by: context[:current_resource],
      )
      model.save!
      model.rig_inspection_template.update(dropzone: model)

      {
        dropzone: model,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        dropzone: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
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

    def authorized?(attributes: nil)
      true
    end
  end
end
