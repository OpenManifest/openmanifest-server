# frozen_string_literal: true

module Types
  module AnyResourceType
    include Types::BaseInterface
    field :id, ID, null: false

    definition_methods do
      # Determine what object type to use for `object`
      def resolve_type(object, context)
        ::DzSchema.resolve_type(object.class, object, context)
      end
    end
  end
end
