# frozen_string_literal: true

require "rails_helper"

# BUG-014: the API answers browsers only for the configured frontends
RSpec.describe "CORS" do
  def preflight(origin)
    options "/graphql", headers: {
      "Origin" => origin,
      "Access-Control-Request-Method" => "POST",
      "Access-Control-Request-Headers" => "content-type,access-token,client,uid",
    }
  end

  it "allows the default local frontends" do
    %w(http://localhost:19006 http://localhost:8081).each do |origin|
      preflight(origin)

      expect(response.headers["Access-Control-Allow-Origin"]).to eq(origin)
      expect(response.headers["Access-Control-Allow-Methods"]).to include("POST")
    end
  end

  it "does not answer a preflight from any other origin" do
    preflight("https://evil.example.com")

    expect(response.headers["Access-Control-Allow-Origin"]).to be_nil
  end

  it "does not add CORS headers to a request from another origin" do
    post "/graphql", params: { query: "{ __typename }" }, headers: { "Origin" => "https://evil.example.com" }

    expect(response.headers["Access-Control-Allow-Origin"]).to be_nil
  end

  describe CorsOrigins do
    it "reads the origins from CORS_ORIGINS" do
      env = { "CORS_ORIGINS" => "https://a.example.com, https://b.example.com:8443,," }

      expect(described_class.list(env)).to eq(%w(https://a.example.com https://b.example.com:8443))
    end

    it "falls back to the local frontends" do
      expect(described_class.list({})).to eq(%w(http://localhost:19006 http://localhost:8081))
    end

    it "always allows the origin of FRONTEND_URL, without its path" do
      env = { "CORS_ORIGINS" => "https://a.example.com", "FRONTEND_URL" => "https://app.example.com/confirm/" }

      expect(described_class.list(env)).to eq(%w(https://a.example.com https://app.example.com))
    end

    it "keeps a non-default port and ignores an unusable FRONTEND_URL" do
      expect(described_class.list("FRONTEND_URL" => "http://local.openmanifest.org:19006")).to include("http://local.openmanifest.org:19006")
      expect(described_class.list("FRONTEND_URL" => "not a url")).to eq(%w(http://localhost:19006 http://localhost:8081))
    end

    it "never allows every origin" do
      expect(described_class.list).not_to include("*")
    end
  end
end
