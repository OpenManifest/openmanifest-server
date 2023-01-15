# frozen_string_literal: true

module Mutations::Users
  class ConfirmUser < ::Mutations::BaseMutation
    argument :token, String, required: false

    field :authenticatable, Types::Users::User, null: true
    field :credentials, Types::Users::User, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true

    def resolve(token:)
      user = User.confirm_by_token(token)

      ::Activity::Event.create(
        level: :debug,
        message: "User confirmed: #{user.email}",
        resource: user,
        action: :confirmed,
        access_level: :admin,
      )

      {
        authenticable: user,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        authenticatable: nil,
        credentials: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotSaved => invalid
      # Failed save, return the errors to the client
      {
        authenticatable: nil,
        credentials: nil,
        field_errors: nil,
        errors: invalid.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        authenticatable: nil,
        credentials: nil,
        field_errors: nil,
        errors: [error.message],
      }
    end
  end
end
