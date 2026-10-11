# frozen_string_literal: true

module Mutations::Users
  class UpdateUser < Mutations::BaseMutation
    field :dropzone_user, Types::Users::DropzoneUser, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true

    argument :attributes, Types::Input::UserInput, required: true
    argument :dropzone_user, ID, required: false,
                                 prepare: -> (value, ctx) { DropzoneUser.find_by(id: value) }

    PROFILE_ATTRIBUTES = %i(name nickname push_token image federation_number phone email license exit_weight).freeze

    # Only the attributes that were sent are passed on: `pushToken: null` clears the push token, leaving it out keeps it.
    # Without a member (logging out before choosing a dropzone) the caller updates their own profile.
    def resolve(attributes: nil, dropzone_user: nil)
      current_user = context[:current_resource]
      mutate(
        ::Users::UpdateUser,
        :dropzone_user,
        access_context: dropzone_user ? access_context_for(dropzone_user.dropzone_id) : ::ApplicationInteraction::AccessContext.new(nil, user: current_user),
        dropzone_user: dropzone_user,
        user: dropzone_user ? nil : current_user,
        **attributes.to_h.slice(*PROFILE_ATTRIBUTES)
      )
    end
  end
end
