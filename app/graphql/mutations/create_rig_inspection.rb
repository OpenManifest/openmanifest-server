# frozen_string_literal: true

module Mutations
  class CreateRigInspection < Mutations::BaseMutation
    field :rig_inspection, Types::RigInspectionType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :attributes, Types::Input::RigInspectionInput, required: true
    argument :id, Int, required: false

    def resolve(attributes:, id: nil)
      dropzone = Dropzone.find(attributes[:dropzone_id])
      rig = Rig.find(attributes[:rig_id])
      dz_user = dropzone.dropzone_users.find_by(user_id: rig.user.id)

      model = RigInspection.find_or_initialize_by(
        rig: rig,
        dropzone_user_id: dz_user.id
      )
      model.assign_attributes(attributes.to_h.except(:dropzone_id))

      model.form_template = dropzone.rig_inspection_template
      model.inspected_by = context[:current_resource].dropzone_users.find_by(dropzone: dropzone)

      model.save!

      {
        rig_inspection: model,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        rig_inspection: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotSaved => invalid
      # Failed save, return the errors to the client
      {
        rig_inspection: nil,
        field_errors: nil,
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        rig_inspection: nil,
        field_errors: nil,
        errors: [ error.message ]
      }
    end

    def authorized?(attributes: nil)
      if context[:current_resource].can?(
        "actAsRigInspector",
        dropzone_id: attributes[:dropzone_id]
      )
        true
      else
        return false, {
          errors: [
            "You don't have permissions to inspect rigs"
            ]
          }
      end
    end
  end
end
