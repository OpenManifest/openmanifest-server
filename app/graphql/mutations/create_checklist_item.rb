module Mutations
  class CreateChecklistItem < Mutations::BaseMutation
    field :checklist_item, Types::ChecklistItemType, null: true

    argument :attributes, Types::Input::ChecklistItemInput, required: true
    argument :id, Int, required: false

    def resolve(attributes:, id: nil)
      model = find_or_build_model(id)
      model.attributes = attributes.to_h

      if model.save
        {checklist_item: model}
      else
        {errors: model.errors.full_messages}
      end
    end

    def find_or_build_model(id)
      if id
        ChecklistItem.find(id)
      else
        ChecklistItem.new
      end
    end
  end
end