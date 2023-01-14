# frozen_string_literal: true

module Mutations::Setup::Aircrafts
  class CreatePlane < Mutations::BaseMutation
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true
    field :plane, Types::Dropzone::Aircraft, null: true

    argument :attributes, Types::Input::PlaneInput, required: true

    def resolve(attributes:)
      mutate(
        ::Setup::Aircrafts::CreateAircraft,
        :plane,
        access_context: access_context_for(attributes[:dropzone_id]),
        **attributes.to_h.slice(
          :name,
          :min_slots,
          :max_slots,
          :hours,
          :registration
        )
      )
    end
  end
end
