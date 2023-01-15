# frozen_string_literal: true

module Mutations::Manifest
  class CreateLoad < Mutations::BaseMutation
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true
    field :load, Types::Manifest::Load, null: true

    argument :attributes, Types::Input::LoadInput, required: true

    def resolve(attributes:)
      dropzone = attributes[:plane].dropzone

      Time.use_zone(dropzone.time_zone) do
        mutate(
          ::Manifest::CreateLoad,
          :load,
          access_context: access_context_for(dropzone),
          **attributes.to_h.slice(
            :name,
            :plane,
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

  def authorized?(attributes: nil)
    current_user = attributes[:plane].dropzone.dropzone_users.find_by(user: context[:current_resource])
    current_user.can?(:createLoad)
  end
end
