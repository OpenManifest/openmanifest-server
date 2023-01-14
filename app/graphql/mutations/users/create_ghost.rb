# frozen_string_literal: true

module Mutations::Users
  class CreateGhost < Mutations::BaseMutation
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true
    field :user, Types::Users::User, null: true

    argument :attributes, Types::Input::GhostInput, required: true

    def resolve(attributes:)
      mutate(
        ::Setup::Users::CreateGhost,
        :user,
        license: attributes[:license],
        role: attributes[:role],
        dropzone: attributes[:dropzone],
        exit_weight: attributes[:exit_weight],
        email: attributes[:email],
        phone: attributes[:phone],
        name: attributes[:name],
      )
    end
  end
end
