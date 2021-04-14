module Mutations
  class DeleteSlot < Mutations::BaseMutation
    field :slot, Types::SlotType, null: true

    argument :id, Int, required: true

    def resolve(id:)
      model = Slot.find(id)

      model.destroy
      {slot: model}
    end
  end
end