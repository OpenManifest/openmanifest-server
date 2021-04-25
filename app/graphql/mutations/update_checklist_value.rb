module Mutations
  class UpdateChecklistValue < Mutations::BaseMutation
    field :checklist_value, Types::ChecklistValueType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :attributes, Types::Input::ChecklistValueInput, required: true

    def resolve(attributes:, id: nil)
      model = ChecklistValue.find_or_initialize_by(
        checklist_item_id: attributes[:checklist_item_id],
        rig_inspection_id: attributes[:rig_inspection_id],
      )
      model.assign_attributes(attributes.to_h)
      model.created_by ||= context[:current_resource]
      model.updated_by = context[:current_resource]

      model.save!

      {
        checklist_value: model,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        checklist_value: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotSaved => error
      # Failed save, return the errors to the client
      {
        checklist_value: nil,
        field_errors: nil,
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        checklist_value: nil,
        field_errors: nil,
        errors: [ error.message ]
      }
    end

    def authorized?(attributes: nil)
      # FIXME: This will only work for rig inspections and not all checklists
      dropzone = Dropzone.find_by(
        checklist_id: ChecklistItem.find(attributes[:checklist_item_id]).checklist.id
      )

      if context[:current_resource].can?(
        "actAsRigInspector",
        dropzone_id: dropzone.id
      )
        return true
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