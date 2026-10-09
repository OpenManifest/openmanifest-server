# frozen_string_literal: true

module Mutations::Users
  class JoinDropzone < Mutations::BaseMutation
    description "Become a member of a public dropzone. Joining a dropzone you already belong to returns your membership."

    field :dropzone_user, Types::Users::DropzoneUser, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true

    argument :dropzone, GraphQL::Types::ID, required: true,
                                            prepare: -> (id, ctx) { Dropzone.kept.find_by(id: id) }

    def resolve(dropzone:)
      return { dropzone_user: nil, errors: ["This dropzone cannot be joined"], field_errors: nil } unless dropzone

      mutate(
        ::Users::JoinDropzone,
        :dropzone_user,
        user: context[:current_resource],
        dropzone: dropzone,
      )
    end
  end
end
