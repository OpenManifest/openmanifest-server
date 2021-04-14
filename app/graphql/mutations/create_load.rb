module Mutations
  class CreateLoad < Mutations::BaseMutation
    field :load, Types::LoadType, null: true

    argument :attributes, Types::Input::LoadInput, required: true

    def resolve(attributes:)
      model = Load.new(attributes.to_h)

      if model.save
        {load: model}
      else
        model_errors!(model)
      end
    end
  end
end