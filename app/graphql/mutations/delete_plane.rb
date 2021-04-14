module Mutations
  class DeletePlane < Mutations::BaseMutation
    field :plane, Types::PlaneType, null: true

    argument :id, Int, required: true

    def resolve(id:)
      model = Plane.find(id)

      model.destroy
      {plane: model}
    end
  end
end