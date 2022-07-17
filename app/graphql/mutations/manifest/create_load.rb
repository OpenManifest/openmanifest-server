# frozen_string_literal: true

module Mutations::Manifest
  class CreateLoad < Mutations::BaseMutation
    field :load, Types::LoadType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :attributes, Types::Input::LoadInput, required: true

    def resolve(attributes:)
      mutation(
        ::Manifest::CreateLoad,
        access_context: access_context_for(attributes[:plane].dropzone),
        **attributes.to_h.slice(
          :name,
          :pilot,
          :gca,
          :load_master,
          :state,
          :max_slots
        )
      )
    end
  end
end
