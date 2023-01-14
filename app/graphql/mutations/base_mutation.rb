# frozen_string_literal: true

module Mutations
  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    include Types::Interfaces::ActiveInteraction
    argument_class Types::Base::Argument
    field_class Types::Base::Field
    input_object_class Types::Base::Input
    object_class Types::Base::Object

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
