# frozen_string_literal: true

module Mutations::Users
  class SignUp < GraphqlDevise::Mutations::SignUp
    argument :phone, String, required: true
    argument :exit_weight, Float, required: true
    argument :name, String, required: true
    argument :license_id, Int, required: false
    argument :push_token, String, required: false

    field :authenticatable, Types::UserType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    # Override devises initializer to allow
    # signing up on an existing user if the user
    # was created by staff
    def build_resource(attrs)
      resource = User.find_or_initialize_by(unconfirmed_email: attrs[:email])
      resource.assign_attributes(attrs)
      resource.skip_confirmation! unless Rails.env.production?
      resource
    end

    def resolve(email:, **attrs)
      original_payload = super

      original_payload.merge(
        authenticatable: original_payload[:authenticatable],
        errors: nil,
        field_errors: nil,
      )
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        authenticatable: nil,
        credentials: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotSaved => invalid
      # Failed save, return the errors to the client
      {
        authenticatable: nil,
        credentials: nil,
        field_errors: nil,
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        authenticatable: nil,
        credentials: nil,
        field_errors: nil,
        errors: [ error.message ]
      }
    end
  end
end
