# frozen_string_literal: true

class Mutations::Users::Register::Base < GraphqlDevise::Mutations::Base
  argument :confirm_url, String, required: false, description: "Used to create the redirect URL"

  field :errors, [String], null: true
  field :field_errors, [Types::FieldErrorType], null: true
  field :authenticatable, Types::UserType, null: true
  field :credentials,
        GraphqlDevise::Types::CredentialType,
        null:        true,
        description: "Authentication credentials. Null if after signUp resource is not active for authentication (e.g. Email confirmation required)."

  def resource_class
    User
  end

  def resolve(confirm_url: nil, **attrs)
    resource = build_resource(attrs.merge(provider: provider))
    raise_user_error(I18n.t("graphql_devise.resource_build_failed")) if resource.blank?

    redirect_url = confirm_url || DeviseTokenAuth.default_confirm_success_url || ENV["FRONTEND_URL"] || ""
    if confirmable_enabled? && redirect_url.blank?
      raise_user_error(I18n.t("graphql_devise.registrations.missing_confirm_redirect_url"))
    end

    check_redirect_url_whitelist!(redirect_url)

    resource.skip_confirmation_notification! if resource.respond_to?(:skip_confirmation_notification!)

    if resource.save
      yield resource if block_given?

      unless resource.confirmed?
        resource.send_confirmation_instructions(
          redirect_url:  redirect_url,
          template_path: ["graphql_devise/mailer"]
        )
      end

      response_payload = { authenticatable: resource }
      response_payload[:credentials] = set_auth_headers(resource) if resource.active_for_authentication?
      response_payload
    else
      resource.try(:clean_up_passwords)
      raise_user_error_list(
        I18n.t("graphql_devise.registration_failed"),
        errors: resource.errors.full_messages
      )
    end
  end

  def set_auth_headers(resource)
    resource.create_new_auth_token
  end

  private
    def build_resource(attrs)
      resource_class.new(attrs)
    end
end
