# frozen_string_literal: true

module Types::Interfaces
  module Polymorphic
    include Types::Base::Interface
    graphql_name 'AnyResource'
    field :id, ID, null: false
    field :guid, ID, null: false
    def guid
      object.to_gid_param
    end

    definition_methods do
      # Determine what object type to use for `object`
      def resolve_type(object, context)
        type, = ::DzSchema.resolve_type(object.class, object, context)
        type
      end
    end
  end
end
