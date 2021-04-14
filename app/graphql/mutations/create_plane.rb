module Mutations
  class CreatePlane < Mutations::BaseMutation
    field :plane, Types::PlaneType, null: true

    argument :attributes, Types::Input::PlaneInput, required: true

    def resolve(attributes:)
      model = Plane.new(attributes.to_h)

      if model.save
        {plane: model}
      else
        model_errors!(model)
      end
    end
  end
end