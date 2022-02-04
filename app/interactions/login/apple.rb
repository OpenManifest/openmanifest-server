# frozen_string_literal: true

require "active_interaction"

class Login::Apple < ActiveInteraction::Base
  include ActiveInteraction::Extras::All
  APPLE_PEM_URL = "https://appleid.apple.com/auth/keys"
  run_in_transaction!
  string :token
  string :user_identity

  class AuthenticationFailed < StandardError
  end

  # Apple JWT token:
  # {
  #     "iss": "https://appleid.apple.com",
  #     "aud": "host.exp.Exponent",
  #     "exp": 1644063376,
  #     "iat": 1643976976,
  #     "sub": "4389032094392.cecscom3299042r049244243.1234",
  #     "c_hash": "eqwdQEDQEeQDFQFC",
  #     "email": "someemail123412@privaterelay.appleid.com",
  #     "email_verified": "true",
  #     "is_private_email": "true",
  #     "auth_time": 1643976976,
  #     "nonce_supported": true,
  #     "real_user_status": 2
  # }

  # /api/apple/validate
  def execute
    jwt = token

    header_segment, = jwt.split(".").take(2).map do |encoded|
      JSON.parse(
        Base64.decode64(encoded),
      )
    end

    alg = header_segment["alg"]
    kid = header_segment["kid"]

    apple_response = HTTParty.get(APPLE_PEM_URL)
    apple_certificate = JSON.parse(
      apple_response.body,
    )

    jwk = JWT::JWK.import(
      apple_certificate["keys"].find { |key| key["kid"] == kid }
    )

    token_data, = JWT.decode(
      jwt,
      jwk.public_key,
      true,
      algorithm: alg
    ).first

    if token_data.has_key?("sub") && token_data.has_key?("email") && user_identity == token_data["sub"]
      puts "Name: " + token_data["name"] + " is validated."

      user = User.find_or_initialize_by(
        provider: :apple,
        uid: token_data["sub"],
      )

      if user.new_record?
        user.assign_attributes(
          email: token_data["email"],
          name: token_data["name"],
          provider: :apple,
          uid: token_data["sub"],
        )
        user.password = SecureRandom.urlsafe_base64(9) unless user.password.present?
        user.save(validate: false)
        user.confirm
        user.save
      end
      user
    else
      raise AuthenticationFailed, "#{token_data} doesn't have sub, email"
    end
  end
end
