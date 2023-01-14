# frozen_string_literal: true

class DzSchema < GraphQL::Schema
  default_page_size 50
  use GraphqlDevise::SchemaPlugin.new(
    query: Types::QueryType,
    mutation: Types::MutationType,
    public_introspection: true,
    resource_loaders: [
      GraphqlDevise::ResourceLoader.new(User, operations: {
        register: Mutations::Users::SignUp,
      }),
    ]
  )
  use(GraphQL::Dataloader)
  use(GraphQL::Tracing::AppsignalTracing)
  mutation(Types::MutationType)
  query(Types::QueryType)

  class << self
    def model_type_map
      @model_class_map ||= {
        ::Dropzone => ::Types::DropzoneType,
        ::DropzoneUser => ::Types::Users::DropzoneUser,
        ::Extra => ::Types::Dropzone::Tickets::Addon,
        ::Federation => ::Types::Meta::Federation,
        ::FormTemplate => ::Types::Equipment::RigInspectionTemplate,
        ::License => ::Types::Meta::License,
        ::LicensedJumpType => ::Types::Meta::LicensedJumpType,
        ::Load => ::Types::Manifest::Load,
        ::Notification => ::Types::System::Notification,
        ::Order => ::Types::Payments::Order,
        ::Permission => ::Types::Access::PermissionType,
        ::Plane => ::Types::Dropzone::Aircraft,
        ::Receipt => ::Types::Payments::Receipt,
        ::Rig => ::Types::Equipment::Rig,
        ::RigInspection => ::Types::Equipment::RigInspection,
        ::Slot => ::Types::Manifest::Slot,
        ::TicketType => ::Types::Dropzone::Ticket,
        ::Transaction => ::Types::Payments::Transaction,
        ::User => ::Types::Users::User,
        ::UserRole => ::Types::Access::UserRole,
        ::UserFederation => ::Types::Users::UserFederation,
        ::WeatherCondition => ::Types::Dropzone::Weather::Condition,
        nil => ::Types::Base::Object,
      }
    end

    # Union and Interface Resolution
    def resolve_type(abstract_type, obj, ctx)
      model_type_map[obj.class]
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
