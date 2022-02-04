# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mutations::Users::Login::Facebook do
  before do
    # Should be:

    # Header:
    # {
    # "alg": "RS256",
    # "typ": "JWT"
    # }
    # Payload:
    # {
    # "sub": "1234567890",
    # "name": "Rspec Spector",
    # "admin": true,
    # "iat": 1516239022
    # }

    header = { alg: "RS256", typ: "JWT", kid: "12345" }
    payload = { 'sub': "1234567890", 'name': "Rspec Specson", 'admin': true, 'iat': 1516239022, 'email': "user@rspec.com" },

    rsa_private = OpenSSL::PKey::RSA.generate(2048)
    jwk = JWT::JWK.new(rsa_private, "12345")

    @token = JWT.encode(payload, jwk.keypair, "RS256", header)

    stub_request(:get, ::Login::Apple::APPLE_PEM_URL).
    to_return(
      headers: { "Content-Type" => "text/plain" },
      body: {
        keys: [jwk.export]
      }.to_json)
  end
  it_behaves_like "graphql", -> { {
    actor: nil,
    permissions: [],
    expect: {
      mutation: {
        loginWithApple: {
          args: {
            token: @token,
            user_identity: "1234567890",
            confirm_url: "https://openmanifest.org/"
          },
          authenticatable: {
            id: /\d/,
            email: "user@rspec.com",
            name: "Rspec Specson",
          },
          credentials: {
            accessToken: /[a-zA-Z0-9\-_]+/,
            tokenType: "Bearer",
            client: /\w+/,
            expiry: /\d+/,
            uid: "1234567890"
          }
        }
      }
    }
  }}
end
