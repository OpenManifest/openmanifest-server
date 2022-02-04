# frozen_string_literal: true

class Mutations::Users::Login::Apple < Mutations::Users::Register::Base
  argument :token, String, required: true
  argument :authorization_code, String, required: true
  argument :push_token, String, required: false

  # Override devises initializer to allow
  # signing up on an existing user if the user
  # was created by staff
  def build_resource(attrs)
    ::Login::Apple.run!(token: attrs[:token], authorization_code: attrs[:authorization_code])
  rescue
    raise Login::Facebook::AuthenticationFailed
  end

  def resolve(**attrs)
    original_payload = super

    original_payload.merge(
      authenticatable: original_payload[:authenticatable],
      errors: nil,
      field_errors: nil,
    )
  rescue Login::Apple::AuthenticationFailed
    {
      authenticatable: nil,
      credentials: nil,
      field_errors: nil,
      errors: ["Apple authentication failed"]
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
