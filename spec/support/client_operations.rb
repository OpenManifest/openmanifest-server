# frozen_string_literal: true

module ClientOperations
  ROOT = Rails.root.join("spec/fixtures/client_operations")

  def self.definitions
    @definitions ||= Dir[ROOT.join("**/*.gql")].flat_map { |f| GraphQL.parse(File.read(f)).definitions }
  end

  def self.operations = definitions.grep(GraphQL::Language::Nodes::OperationDefinition).index_by(&:name)

  def self.fragments = definitions.grep(GraphQL::Language::Nodes::FragmentDefinition).index_by(&:name)

  # Returns the query string for the named client operation plus every fragment it uses (transitively).
  def self.document(name)
    op = operations.fetch(name) { raise KeyError, "No client operation named #{name}" }
    needed = []
    queue = [op]
    until queue.empty?
      node = queue.shift
      spreads = []
      collect = lambda do |n|
        spreads << n.name if n.is_a?(GraphQL::Language::Nodes::FragmentSpread)
        n.children.each { |c| collect.call(c) } if n.respond_to?(:children)
      end
      collect.call(node)
      spreads.uniq.each do |s|
        next if needed.include?(s)

        needed << s
        queue << fragments.fetch(s)
      end
    end
    ([op] + needed.map { |s| fragments.fetch(s) }).map(&:to_query_string).join("\n")
  end
end
