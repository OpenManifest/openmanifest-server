# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Client operation harness" do
  it "knows all 77 client operations" do
    expect(ClientOperations.operations.keys.size).to eq(77)
  end

  ClientOperations.operations.keys.sort.each do |name|
    it "validates #{name} against the schema" do
      query = GraphQL::Query.new(DzSchema, ClientOperations.document(name))
      errors = GraphQL::StaticValidation::Validator.new(schema: DzSchema).validate(query)[:errors]
      expect(errors.map(&:message)).to be_empty
    end
  end
end
