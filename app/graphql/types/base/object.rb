# frozen_string_literal: true

module Types::Base
  class Object < GraphQL::Schema::Object
    include Support::Objects
    edge_type_class(Types::Base::Edge)
    connection_type_class(Types::Base::Connection)
    field_class Types::Base::Field
  end
end
