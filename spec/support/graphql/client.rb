# frozen_string_literal: true

require "rspec/json_expectations"
module Specs
  module Graphql
    class Client
      class QueryNotExecutedError < StandardError; end
      include RSpec::JsonExpectations::Matchers
      attr_accessor :query_document,
                    :query_string,
                    :variables,
                    :pundit_user,
                    :match_hash,
                    :operation_name,
                    :result

      def initialize(query_hash, actor: nil, controller: nil)
        @actor = actor
        @controller = controller
        query_hash = query_hash.deep_transform_keys { |k| k.to_s.camelize(:lower).to_sym }
        self.operation_name = (query_hash[:mutation] || query_hash[:query]).keys.first
        if query_hash.key?(:mutation)
          query_hash[:mutation][operation_name][:fieldErrors] = {
            message: "",
            field: "",
          }
          query_hash[:mutation][operation_name][:errors] = nil
        end
        query_document = GraphQL.parse(
          from_hash(query_hash)
        )
        self.query_string = GraphQL::Language::Printer.new.print(query_document)
        self.pundit_user = pundit_user
        self.match_hash = deep_reject(query_hash[:mutation] || query_hash[:query]) { |k, v| k == :args }
        match_hash[operation_name][:fieldErrors] = nil
        match_hash[operation_name][:errors] = nil
      end

      def execute
        self.result = DzSchema.execute(
          query_string,
          operation_name: operation_name.to_s.to_s.camelize(:upper),
          variables: {},
          context: {
            current_resource: @actor,
            controller: @controller,
          }
        )
        warn "Executing query:"
        warn query_string
        self
      end

      # This allows us to create the special graphql input
      # arguments and is required to be able to support graphql
      # enums, which are strings not surrounded by "". In Ruby,
      # we represent this with symbols
      def create_input_arguments(item, depth = 0)
        if item.is_a?(Hash)
          result = item.reduce(nil) do |str, (key, value)|
            [str, "#{key}: #{create_input_arguments(value, depth + 1)}"].reject(&:nil?).join(", ")
          end
          if depth != 0
            "{ %s }" % result
          else
            result
          end
        elsif item.is_a?(Array)
          "[#{item.map { |v| create_input_arguments(v, depth + 1) }.reject(&:nil?).join(', ')}]"
        elsif item.is_a?(Symbol)
          item.to_s
        else
          item.to_json
        end
      end

      def from_hash(hash_or_array, depth = 0)
        hash_or_array.map do |key, value|
          # SPECIAL CASE:
          # ':args' is a reserved keyword and will be
          # used to create input arguments for this node
          value = value.array if value.is_a?(UnorderedArrayMatcher)
          if value.is_a?(Hash)
            if value.key?(:args)
              input_args = "(#{create_input_arguments(value[:args])})"
            end
            input_args ||= ""
            key = "%s %s" % [key.to_s, "#{operation_name.to_s.camelize(:upper)}"] if depth == 0

            "
              #{key.to_s.camelize(:lower)}#{input_args} {
                  #{from_hash(value.except(:args), depth + 1)}
              }
            "
          elsif value.is_a?(Array)
            if value.size > 0 && value.all? { |item| item.is_a?(Hash) }
              "
                #{key} {
                  #{from_hash(value.reduce(:merge).except(:args), depth + 1)}
                }
              "
            else
              "
                #{key.to_s.camelize(:lower)}
              "
            end
          else
            k = key unless key.is_a?(Hash)
            k ||= key.keys.uniq.map { |s| s.to_s.camelize(:lower) }.join(",")
            "
              #{k}
            "
          end
        end.join
      end

      def deep_reject(hash, &block)
        hash.each_with_object({}) do |(k, v), memo|
          unless block.call(k, v)
            if v.is_a?(Hash)
              memo[k] = deep_reject(v, &block)
            else
              memo[k] = v
            end
          end
        end
      end
    end
  end
end
