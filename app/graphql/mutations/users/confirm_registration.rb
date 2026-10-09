# frozen_string_literal: true

# Confirming an account signs the user in. Like the gem's login, make them the current resource so that the payload can
# show their own email, phone and push token (Types::Users::User only reveals those to the user themselves and to staff).
class Mutations::Users::ConfirmRegistration < GraphqlDevise::Mutations::ConfirmRegistrationWithToken
  # Keeps the payload type name of the gem's own operation, so the schema does not change
  graphql_name "UserConfirmRegistrationWithToken"

  # Custom operations do not get the authenticatable field of the gem's own ones
  field :authenticatable, Types::Users::User, null: false

  def resolve(confirmation_token:)
    super do |resource|
      context[:current_resource] = resource if context[:current_resource].nil?
    end
  end
end
