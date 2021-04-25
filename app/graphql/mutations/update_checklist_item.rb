module Mutations
  class UpdateChecklistItem < Mutations::BaseMutation
    field :checklist_item, Types::ChecklistItemType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true


    argument :attributes, Types::Input::ChecklistItemInput, required: true
    argument :id, Int, required: false

    def resolve(attributes:, id: nil)
      model = ChecklistItem.find(id)
      model.assign_attributes(attributes.to_h)

      model.save!

      {
        checklist_item: model,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        checklist_item: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotSaved => error
      # Failed save, return the errors to the client
      {
        checklist_item: nil,
        field_errors: nil,
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        checklist_item: nil,
        field_errors: nil,
        errors: [ error.message ]
      }
    end

    def authorized?(attributes: nil, id: nil)
      # FIXME: This will only work for rig inspections and not all checklists
      dropzone = Dropzone.find_by(
        rig_inspection_checklist_id: ChecklistItem.find(id).checklist.id
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