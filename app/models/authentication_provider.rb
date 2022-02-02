# frozen_string_literal: true

class AuthenticationProvider < ApplicationRecord
  class AuthenticationFailed < StandardError
  end
  belongs_to :user
  enum provider: [
    :apple,
    :facebook,
    :instagram
  ]

  def self.facebook(token:)
    transaction do
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

      provider = find_or_initialize_by(
        provider: :facebook,
        uid: response.parsed_response["id"],
      )

      if provider.new_record?
        provider.user = User.find_or_create_by(
          email: response.parsed_response["email"],
          provider: :facebook,
          uid: response.parsed_response["id"],
        )
        provider.user.password = SecureRandom.urlsafe_base64(9)
        provider.user.save(validate: false)
        provider.user.confirm
        provider.save!
      end
      provider.user.update!(user_attributes)
      provider
    end
  rescue => error
    puts error.message
    raise AuthenticationFailed
  end
end
