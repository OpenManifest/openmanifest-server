# frozen_string_literal: true

module Mutations::Access
  class UpdateVisibility < Mutations::BaseMutation
    field :operator, Types::OperatorType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true

    argument :operator, GraphQL::Types::ID, required: true,
                                            prepare: -> (id, ctx) { Operator.find_by(id: id) }
    argument :event, Types::Operator::StateEvent, required: true

    def resolve(operator:, event:)
      mutate(
        Setup::Operators::UpdateVisibility,
        :operator,
        access_context: access_context_for(
          operator
        ),
        operator: operator,
        event: event,
      )
    end
  end
end
