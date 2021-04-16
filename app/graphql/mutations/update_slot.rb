# frozen_string_literal: true

module Mutations
  class UpdateSlot < Mutations::BaseMutation
    field :slot, Types::SlotType, null: true

    argument :id, Int, required: true
    argument :attributes, Types::Input::SlotInput, required: true

    def resolve(attributes:, id:)
      model = Slot.find(id)

      if model.update(attributes.to_h)
        { slot: model }
      else
        model_errors!(model)
      end
    end
  end
end
