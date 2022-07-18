# frozen_string_literal: true

module Mutations::Setup::RigInspections
  class UpdateRigInspection < Mutations::BaseMutation
    field :rig_inspection, Types::RigInspectionType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true


    argument :attributes, Types::Input::RigInspectionInput, required: true
    argument :id, Int, required: false

    def resolve(attributes:, id: nil)
      model = RigInspection.find(id)
      model.assign_attributes(attributes.to_h)


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
