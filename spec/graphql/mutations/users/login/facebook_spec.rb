# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mutations::Users::Login::Facebook do
  before do
    token = "12345"
    stub_request(:get, "https://graph.facebook.com/me?access_token=%s&fields=name,email,picture" % token).
      to_return(
        headers: { "Content-Type" => "application/json" },
        body: {
          "id": "427773",
          "email": "user@rspec.com",
          "name": "Rspec User",
        }.to_json
      )
  end

  it_behaves_like "graphql", {
    actor: nil,
    permissions: [],
    expect: {
      mutation: {
        loginWithFacebook: {
          args: {
            token: "12345",
            confirm_url: "https://openmanifest.org/",
          },
          authenticatable: {
            id: /\d/,
            email: "user@rspec.com",
            name: "Rspec User",
          },
          credentials: {
            accessToken: /[a-zA-Z0-9\-_]+/,
            tokenType: "Bearer",
            client: /\w+/,
            expiry: /\d+/,
            uid: "427773",
          },
        },
      },
    },
  }
end
