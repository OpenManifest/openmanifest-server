# frozen_string_literal: true

require "rails_helper"

# The API no longer serves the stale 2021 web build (BUG-059, P2.1); the web app is hosted separately.
RSpec.describe "Static routes", type: :request do
  ["/", "/index.html", "/confirm"].each do |path|
    it "does not route GET #{path}" do
      expect { get path }.to raise_error(ActionController::RoutingError)
    end
  end

  it "serves the Apple app site association file for universal links" do
    get "/.well-known/apple-app-site-association"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to have_key("applinks")
  end

  it "serves the GraphQL endpoint" do
    get "/graphql"

    expect(response).to have_http_status(:ok)
  end
end
