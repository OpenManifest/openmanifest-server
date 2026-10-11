# frozen_string_literal: true

module Mutations::Users
  class SignUp < GraphqlDevise::Mutations::Register
    argument :exit_weight, Float, required: true
    argument :license_id, Int, required: false
    argument :name, String, required: true
    argument :phone, String, required: true
    argument :push_token, String, required: false

    field :authenticatable, Types::Users::User, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true

    # A new account is always a new user. The confirmation step is only skipped (outside production) for the account
    # created here, never for an existing one
    def build_resource(attrs)
      resource = User.new(attrs)
      resource.skip_confirmation! unless Rails.env.production?
      resource
    end

    def resolve(email:, confirm_url: nil, **attrs)
      # An account for this email that nobody confirmed yet (a ghost created by staff, or an earlier sign-up): it is not
      # touched and no session is started; the email's owner gets the confirmation email again and claims it by
      # confirming (BUG-012)
      return claim_pending_account(email, confirm_url) if ::Users::ClaimGhost.pending_account(email)

      original_payload = super do |resource|
        # The caller is this user from here on, like after the gem's login: it lets the payload show their own email,
        # phone and push token (Types::Users::User only reveals those to the user themselves and to staff)
        context[:current_resource] = resource if context[:current_resource].nil?
      end

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

    private

    # The answer looks like a sign-up that needs confirming: no credentials, and nothing about the account
    def claim_pending_account(email, confirm_url)
      redirect_url = confirm_url || DeviseTokenAuth.default_confirm_success_url
      raise_user_error(I18n.t("graphql_devise.registrations.missing_confirm_redirect_url")) if redirect_url.blank?
      check_redirect_url_whitelist!(redirect_url)

      outcome = ::Users::ClaimGhost.run(email: email, redirect_url: redirect_url)
      { authenticatable: nil, credentials: nil, errors: outcome.valid? ? nil : outcome.errors.full_messages, field_errors: nil }
    end
  end
end
