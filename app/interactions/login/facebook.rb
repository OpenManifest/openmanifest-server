# frozen_string_literal: true

require "active_interaction"

class Login::Facebook < ActiveInteraction::Base
  include ActiveInteraction::Extras::All
  run_in_transaction!
  string :token

  class AuthenticationFailed < StandardError
  end

  def execute
    response = HTTParty.get(
      "https://graph.facebook.com/me?access_token=%s&fields=name,email,picture" % token,
    )

    user_attributes = {
      name: response.parsed_response["name"],
      email: response.parsed_response["email"],
    }

    if response.parsed_response["picture"] && response.parsed_response["picture"]["data"] && response.parsed_response["picture"]["data"]["url"]
      image_response = HTTParty.get(response.parsed_response["picture"]["data"]["url"])
      user_attributes[:image] = "data:image/png;base64,%s" % Base64.strict_encode64(image_response.parsed_response) if image_response&.parsed_response
    end

    user = User.find_or_initialize_by(
      provider: :facebook,
      uid: response.parsed_response["id"],
    )

    if existing = User.find_by(email: response.parsed_response["email"])
      errors.add(:base, "You need to login with #{existing.provider}") if existing.provider != user.provider
    end

    # Email is unique, so logging in with

    if user.new_record?
      user.assign_attributes(
        email: response.parsed_response["email"],
        provider: :facebook,
        uid: response.parsed_response["id"],
      )
      user.password = SecureRandom.urlsafe_base64(9) unless user.password.present?
      user.save(validate: false)
      user.confirm
      user.save!
    end
    user.assign_attributes(user_attributes)
    errors.merge!(user.errors) unless user.save
    user
  rescue
    raise AuthenticationFailed
  end
end
