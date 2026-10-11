# frozen_string_literal: true

require "rails_helper"

RSpec.describe "schema.graphql" do
  it "matches the schema the server serves" do
    committed = Rails.root.join("schema.graphql").read

    expect(committed).to eq(GraphQL::Schema::Printer.print_schema(DzSchema)),
                         "Run bin/rails graphql:schema:dump and commit schema.graphql"
  end
end
