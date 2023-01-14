# frozen_string_literal: true

module Mutations::Manifest
  class DeleteLoad < Mutations::BaseMutation
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true
    field :load, Types::Manifest::Load, null: true

    argument :id, Int, required: true

    def resolve(id:)
      mutate(
        ::Manifest::DeleteLoad,
        :load,
        access_context: access_context_for(load_by_id(id).dropzone),
        load: load_by_id(id)
      )
    end

    def load_by_id(id)
      @load_by_id ||= Load.find(id)
    end
  end
end
