# frozen_string_literal: true

module Mutations
  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    include Types::Interfaces::ActiveInteraction
    include Support::Authorization

    argument_class Types::Base::Argument
    field_class Types::Base::Field
    input_object_class Types::Base::Input
    object_class Types::Base::Object

    # Creates an AccessContext for the current_resource
    # to be used for permission checking in interactions
    #
    # @param [Operator|Integer] operator_or_operator_id
    # @return [::ApplicationInteraction::AccessContext]
    def access_context_for(operator_or_operator_id)
      if operator_or_operator_id.is_a?(Integer)
        ::ApplicationInteraction::AccessContext.for(
          context[:current_resource],
          operator_id: operator_or_operator_id
        )
      else
        ::ApplicationInteraction::AccessContext.for(
          context[:current_resource],
          operator: operator_or_operator_id
        )
      end
    end
  end
end
