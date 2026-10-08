# frozen_string_literal: true

require "rails_helper"

# Fails when the client gains a GraphQL operation (run bin/sync-client-operations) that no request spec exercises.
# Subscriptions cannot be executed over HTTP, so their specs validate the document with ClientOperations.document.
RSpec.describe "Client operation coverage" do
  let(:spec_sources) do
    Dir[Rails.root.join("spec/requests/client_operations/*_spec.rb")].
      reject { |file| file.end_with?("coverage_spec.rb") }.
      map { |file| File.read(file) }.
      join("\n")
  end

  ClientOperations.operations.keys.sort.each do |name|
    it "has a request spec for #{name}" do
      expect(spec_sources).to match(/(client_operation|ClientOperations\.document)\(\s*["']#{Regexp.escape(name)}["']/)
    end
  end
end
