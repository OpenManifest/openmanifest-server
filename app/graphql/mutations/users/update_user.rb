# frozen_string_literal: true

module Mutations::Users
  class UpdateUser < Mutations::BaseMutation
    field :dropzone_user, Types::Users::DropzoneUser, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true

    argument :attributes, Types::Input::UserInput, required: true
    argument :dropzone_user, ID, required: false,
                                 prepare: -> (value, ctx) { DropzoneUser.find_by(id: value) }

    def resolve(attributes: nil, dropzone_user: nil)
      mutate(
        ::Users::UpdateUser,
        :dropzone_user,
        access_context: access_context_for(dropzone_user.dropzone_id),
        dropzone_user: dropzone_user,
        name: attributes[:name],
        user_role_id: attributes[:user_role_id],
        nickname: attributes[:nickname],
        push_token: attributes[:push_token],
        image: attributes[:image],
        federation_number: attributes[:federation_number],
        phone: attributes[:phone],
        email: attributes[:email],
        license: attributes[:license],
        exit_weight: attributes[:exit_weight],
        expires_at: attributes[:expires_at],
      )
    end
  end
end
