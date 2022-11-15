# frozen_string_literal: true

module Mutations::Setup::Dropzones
  class CreateDropzone < Mutations::BaseMutation
    field :dropzone, Types::DropzoneType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :attributes, Types::Input::DropzoneInput, required: true

    def resolve(attributes:)
      mutate(
        ::Setup::Dropzones::CreateDropzone,
        :dropzone,
        owner: context[:current_resource],
        **attributes.to_h.slice(
          :name,
          :lat,
          :lng,
          :federation,
          :banner,
          :request_publication,
          :is_public,
          :primary_color,
          :secondary_color,
          :is_credit_system_enabled
        )
      )
    end

    def authorized?(attributes: nil)
      true
    end
  end
end
