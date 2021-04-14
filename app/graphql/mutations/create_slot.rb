module Mutations
  class CreateSlot < Mutations::BaseMutation
    field :slot, Types::SlotType, null: true

    argument :attributes, Types::Input::SlotInput, required: true

    def resolve(attributes:)
      model = Slot.new(attributes.to_h)

      if model.save
        {slot: model}
      else
        model_errors!(model)
      end
    end
  end
end