module Types
  module Input
    class ChecklistValueInput < Types::BaseInputObject
      argument :value, String, required: false
      argument :checklist_item_id, Int, required: false
      argument :rig_inspection_id, Int, required: false
    end
  end
end