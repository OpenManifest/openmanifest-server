# frozen_string_literal: true

require "rails_helper"

# The resolver instrumentation is skipped in the test environment, so a gem upgrade that removes an AppSignal API it
# uses (appsignal 5 removed Appsignal::Utils::HashSanitizer) only shows up at runtime. Run it once for real.
RSpec.describe "AppSignal resolver instrumentation" do
  include_context "dropzone"

  it "instruments a resolver and records the variables" do
    allow(Rails.env).to receive(:test?).and_return(false)
    %i(set_action set_namespace tag_request).each { |method| allow(Appsignal).to receive(method) }
    bodies = []
    allow(Appsignal).to receive(:instrument) do |name, _title = nil, body = nil, *, &block|
      bodies << body if name == "graphql.resolver"
      block.call
    end

    json = client_operation("Dropzones", as: user)

    expect(json[:errors]).to be_nil
    expect(bodies).not_to be_empty
    expect(bodies.first).to include("Variables: ", "Query: ")
  end

  it "replaces password values in the sanitized variables" do
    sanitized = Appsignal::Utils::SampleDataSanitizer.sanitize({ "email" => "a@b.c", "password" => "secret" }, ["password"])

    expect(sanitized).to eq("email" => "a@b.c", "password" => "[FILTERED]")
  end
end
