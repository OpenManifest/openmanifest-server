module Mutations
  class UpdatePlane < Mutations::BaseMutation
    field :plane, Types::PlaneType, null: true

    argument :id, Int, required: true
    argument :attributes, Types::Input::PlaneInput, required: true
    
    def resolve(attributes:, id:)
      model = Plane.find(id)

      if model.update(attributes.to_h)
        {plane: model}
      else
        model_errors!(model)
      end
    end
  end
end