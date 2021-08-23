# frozen_string_literal: true

module Mutations
  class FinalizeLoad < Mutations::BaseMutation
    include Types::InteractionMutationInterface
    field :load, Types::LoadType, null: true

    argument :id, Int, required: true
    argument :state, Types::LoadStateType, required: true

    def resolve(state:, id:)
      if state == 'landed'
        mutate(
          :load,
          Loads::Finalize,
          load_id: id
        )
      elsif state == 'cancelled'
        mutate(
          :load,
          Loads::Cancel,
          load_id: id
        )
      end
    end

    def authorized?(id: nil, attributes: nil)
      if context[:current_resource].can?(
        "updateLoad",
        dropzone_id: Load.find(id).plane.dropzone_id
      )
        true
      else
        return false, {
          errors: [
            "You don't have permissions to create ticket addons"
            ]
          }
      end
    end
  end
end
