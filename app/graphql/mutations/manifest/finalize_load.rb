# frozen_string_literal: true

module Mutations::Manifest
  class FinalizeLoad < Mutations::BaseMutation
    include Types::Interfaces::ActiveInteraction

    field :load, Types::Manifest::Load, null: true

    argument :id, Int, required: true
    argument :state, Types::Manifest::LoadState, required: true

    def resolve(state:, id:)
      case state
      when "landed"
        mutate(
          Manifest::FinalizeLoad,
          :load,
          load: load_by_id(id),
          access_context: access_context_for(
            load_by_id(id).dropzone
          )
        )
      when "cancelled"
        mutate(
          Manifest::CancelLoad,
          :load,
          load: load_by_id(id),
          access_context: access_context_for(
            load_by_id(id).dropzone
          )
        )
      else
        { load: nil, field_errors: nil, errors: ["A load can only be finalized as landed or cancelled"] }
      end
    end

    def authorized?(id: nil, state: nil)
      if context[:current_resource].can?(
        "updateLoad",
        dropzone_id: load_by_id(id).plane.dropzone_id
      )
        true
      else
        [
          false, {
            errors: [
              "You don't have permissions to update loads",
            ],
          },
        ]
      end
    end

    private

    def load_by_id(id)
      @load_by_id ||= Load.find(id)
    end
  end
end
