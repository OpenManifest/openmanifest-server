# frozen_string_literal: true

module Mutations::Access
  class UpdateVisibility < Mutations::BaseMutation
    field :dropzone, Types::DropzoneType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true

    argument :dropzone, GraphQL::Types::ID, required: true,
                                            prepare: -> (id, ctx) { Dropzone.find_by(id: id) }
    argument :event, Types::Dropzone::StateEvent, required: true

    def resolve(dropzone:, event:)
      mutate(
        Setup::Dropzones::UpdateVisibility,
        :dropzone,
        access_context: access_context_for(
          dropzone
        ),
        dropzone: dropzone,
        event: event,
      )
    end
  end
end
