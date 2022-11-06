# frozen_string_literal: true

class DzSchema < GraphQL::Schema
  default_page_size 50
  use GraphqlDevise::SchemaPlugin.new(
    query:                Types::QueryType,
    mutation:             Types::MutationType,
    public_introspection: true,
    resource_loaders: [
      GraphqlDevise::ResourceLoader.new(User, operations: {
        register: Mutations::Users::SignUp
      }),
    ]
  )
  use(GraphQL::Tracing::AppsignalTracing)
  mutation(Types::MutationType)
  query(Types::QueryType)

  class << self
    def model_type_map
      @model_class_map ||= {
        ::Dropzone            => ::Types::DropzoneType,
        ::Federation          => ::Types::FederationType,
        ::DropzoneUser        => ::Types::DropzoneUserType,
        ::Form                => ::Types::Form,
        ::License             => ::Types::License,
        ::LicensedJumpType    => ::Types::LicensedJumpType,
        ::Load                => ::Types::Load,
        ::Notification        => ::Types::Notification,
        ::Rig                 => ::Types::Rig,
        ::RigInspection       => ::Types::RigInspection,
        ::FormTemplate        => ::Types::FormTemplate,
        ::Extra               => ::Types::Extra,
        ::Passenger           => ::Types::Passenger,
        ::Permission          => ::Types::Permission,
        ::Plane               => ::Types::Plane,
        ::TicketType          => ::Types::TicketType,
        ::User                => ::Types::User,
        ::UserFederation      => ::Types::UserFederation,
        ::Receipt             => ::Types::Receipt,
        ::Order               => ::Types::Order,
        ::Transaction         => ::Types::Transaction,
        ::WeatherCondition    => ::Types::WeatherCondition,
        ::UserRole            => ::Types::UserRole,
        ::Slot                => ::Types::Slot,
        ::Plane               => ::Types::Plane
      }
    end

    # Union and Interface Resolution
    def resolve_type(abstract_type, obj, ctx)
      model_type_map[abstract_type]
    end

    # Relay-style Object Identification:

    # Return a string UUID for `object`
    def id_from_object(object, type_definition, query_ctx)
      object.to_gid_param
    end

    # Given a string UUID, find the object
    def object_from_id(global_id, query_ctx)
      ::GlobalID.find(global_id)
    end
  end
end
