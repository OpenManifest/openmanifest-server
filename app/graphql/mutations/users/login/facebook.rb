# frozen_string_literal: true

class Mutations::Users::Login::Facebook < Mutations::Users::Register::Base
  argument :token, String, required: true
  argument :push_token, String, required: false

  # Override devises initializer to allow
  # signing up on an existing user if the user
  # was created by staff
  def build_resource(attrs)
    provider = AuthenticationProvider.facebook(token: attrs[:token])
    provider.user.update(push_token: attrs[:push_token]) if attrs[:push_token]
    provider.user
  rescue
    raise AuthenticationProvider::AuthenticationFailed
  end

  def resolve(**attrs)
    original_payload = super

    original_payload.merge(
      authenticatable: original_payload[:authenticatable],
      errors: nil,
      field_errors: nil,
    )
  rescue AuthenticationProvider::AuthenticationFailed
    {
      authenticatable: nil,
      credentials: nil,
      field_errors: nil,
      errors: ["Facebook authentication failed"]
    }
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