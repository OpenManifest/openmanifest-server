# frozen_string_literal: true

module Mutations::Setup::RigInspections
  class UpdateRigInspection < Mutations::BaseMutation
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true
    field :rig_inspection, Types::Equipment::RigInspection, null: true

    argument :attributes, Types::Input::RigInspectionInput, required: true
    argument :id, Int, required: false

    def resolve(attributes:, id: nil)
      model = RigInspection.find(id)
      # An inspection keeps its member, rig and dropzone; only the result and the form answers change
      model.assign_attributes(attributes.to_h.slice(:definition, :is_ok))

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
        errors: invalid.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotSaved => invalid
      # Failed save, return the errors to the client
      {
        rig_inspection: nil,
        field_errors: nil,
        errors: invalid.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        rig_inspection: nil,
        field_errors: nil,
        errors: [error.message],
      }
    end

    def authorized?(attributes: nil, id: nil)
      # The inspection's own dropzone, not the one the client says (BUG-009)
      inspection = RigInspection.find_by(id: id)
      return [false, { errors: ["Rig inspection not found"] }] unless inspection

      if context[:current_resource].can?(
        "actAsRigInspector",
        dropzone_id: inspection.dropzone_user.dropzone_id
      )
        true
      else
        [
          false, {
            errors: [
              "You don't have permissions to inspect rigs",
            ],
          },
        ]
      end
    end
  end
end
