# frozen_string_literal: true

module Mutations::Manifest
  class FinalizeLoad < Mutations::BaseMutation
    include Types::Interfaces::ActiveInteraction

    field :load, Types::Manifest::Load, null: true

    argument :id, Int, required: true
    argument :state, Types::Manifest::LoadState, required: true

    def resolve(state:, id:)
      case state
      when "completed"
        mutate(
          Manifest::FinalizeLoad,
          :load,
          load: load_by_id(id),
          access_context: access_context_for(
            load_by_id(id).operator
          )
        )
      when "cancelled"
        mutate(
          Manifest::CancelLoad,
          :load,
          load: load_by_id(id),
          access_context: access_context_for(
            load_by_id(id).operator
          )
        )
      else
        { load: nil, field_errors: nil, errors: ["A load can only be finalized as completed or cancelled"] }
      end
    end

    def authorized?(id: nil, state: nil)
      if context[:current_resource].can?(
        "updateLoad",
        operator_id: load_by_id(id).vehicle.operator_id
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
