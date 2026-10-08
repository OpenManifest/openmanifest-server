# frozen_string_literal: true

namespace :graphql do
  namespace :schema do
    desc "Write the GraphQL schema served by the API to schema.graphql"
    task dump: :environment do
      Rails.root.join("schema.graphql").write(GraphQL::Schema::Printer.print_schema(DzSchema))
      puts "Wrote schema.graphql"
    end
  end
end
