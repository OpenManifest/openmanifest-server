# frozen_string_literal: true

module Mutations::Users
  class JoinOperator < Mutations::BaseMutation
    description "Become a member of a public operator. Joining an operator you already belong to returns your membership."

    field :membership, Types::Users::Membership, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true

    argument :operator, GraphQL::Types::ID, required: true,
                                            prepare: -> (id, ctx) { Operator.kept.find_by(id: id) }

    def resolve(operator:)
      return { membership: nil, errors: ["This operator cannot be joined"], field_errors: nil } unless operator

      mutate(
        ::Users::JoinOperator,
        :membership,
        user: context[:current_resource],
        operator: operator,
      )
    end
  end
end
