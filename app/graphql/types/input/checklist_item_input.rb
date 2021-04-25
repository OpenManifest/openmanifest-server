module Types
  module Input
    class ChecklistItemInput < Types::BaseInputObject
      argument :value_type, Int, required: false
      argument :is_required, Boolean, required: false
      argument :name, String, required: false
      argument :description, String, required: false
    end
  end
end