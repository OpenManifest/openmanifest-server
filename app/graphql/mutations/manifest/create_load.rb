# frozen_string_literal: true

module Mutations::Manifest
  class CreateLoad < Mutations::BaseMutation
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true
    field :load, Types::LoadType, null: true

    argument :attributes, Types::Input::LoadInput, required: true

    def resolve(attributes:)
      mutate(
        ::Manifest::CreateLoad,
        :load,
        access_context: access_context_for(attributes[:plane].dropzone),
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

  def authorized?(attributes: nil)
    current_user = attributes[:plane].dropzone.dropzone_users.find_by(user: context[:current_resource])
    current_user.can?(:createLoad)
  end
end
