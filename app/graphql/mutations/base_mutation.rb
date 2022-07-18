# frozen_string_literal: true

module Mutations
  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    include Types::InteractionMutationInterface
    argument_class Types::BaseArgument
    field_class Types::BaseField
    input_object_class Types::BaseInputObject
    object_class Types::BaseObject

    # Creates an AccessContext for the current_resource
    # to be used for permission checking in interactions
    #
    # @param [Dropzone|Integer] dropzone_or_dropzone_id
    # @return [::ApplicationInteraction::AccessContext]
    def access_context_for(dropzone_or_dropzone_id)
      if dropzone_or_dropzone_id.is_a?(Integer)
        ::ApplicationInteraction::AccessContext.for(
          context[:current_resource],
          dropzone_id: dropzone_or_dropzone_id
        )
      else
        ::ApplicationInteraction::AccessContext.for(
          context[:current_resource],
          dropzone: dropzone_or_dropzone_id
        )
      end
    end
  end
end
