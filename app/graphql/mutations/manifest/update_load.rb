# frozen_string_literal: true

module Mutations::Manifest
  class UpdateLoad < Mutations::BaseMutation
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true
    field :load, Types::Manifest::Load, null: true

    argument :attributes, Types::Input::LoadInput, required: true
    argument :id, Int, required: true

    def resolve(attributes:, id:)
      mutate(
        Manifest::UpdateLoad,
        :load,
        access_context: access_context_for(load_by_id(id).plane.dropzone),
        load: load_by_id(id),
        **attributes.to_h.slice(
          :gca,
          :load_master,
          :pilot,
          :max_slots,
          :dispatch_at,
          :plane,
          :state,
          :name
        )
      )
    end

    def load_by_id(id)
      @load_by_id ||= Load.find(id)
    end
  end
end
