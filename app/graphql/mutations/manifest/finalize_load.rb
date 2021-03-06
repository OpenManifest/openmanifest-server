# frozen_string_literal: true

module Mutations::Manifest
  class FinalizeLoad < Mutations::BaseMutation
    include Types::InteractionMutationInterface
    field :load, Types::LoadType, null: true

    argument :id, Int, required: true
    argument :state, Types::LoadStateType, required: true

    def resolve(state:, id:)
      if state == "landed"
        mutate(
          Manifest::FinalizeLoad,
          :load,
          load: load_by_id(id),
          access_context: access_context_for(
            load_by_id(id).dropzone
          )
        )
      elsif state == "cancelled"
        mutate(
          Manifest::CancelLoad,
          :load,
          load: load_by_id(id),
          access_context: access_context_for(
            load_by_id(id).dropzone
          )
        )
      end
    end

    def authorized?(id: nil, state: nil)
      if context[:current_resource].can?(
        "updateLoad",
        dropzone_id: load_by_id(id).plane.dropzone_id
      )
        true
      else
        [false, {
          errors: [
            "You don't have permissions to create ticket addons"
          ]
        }]
      end
    end

    private
      def load_by_id(id)
        @load_by_id ||= Load.find(id)
      end
  end
end
