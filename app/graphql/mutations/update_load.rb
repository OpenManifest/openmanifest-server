# frozen_string_literal: true

module Mutations
  class UpdateLoad < Mutations::BaseMutation
    field :load, Types::LoadType, null: true

    argument :id, Int, required: true
    argument :attributes, Types::Input::LoadInput, required: true

    def resolve(attributes:, id:)
      model = Load.find(id)

      if model.update(attributes.to_h)
        { load: model }
      else
        model_errors!(model)
      end
    end
  end
end
