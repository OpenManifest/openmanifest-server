# frozen_string_literal: true

module Mutations
  class DeleteLoad < Mutations::BaseMutation
    field :load, Types::LoadType, null: true

    argument :id, Int, required: true

    def resolve(id:)
      model = Load.find(id)

      model.destroy
      { load: model }
    end
  end
end
