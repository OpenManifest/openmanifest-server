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
  use(GraphQL::Tracing::AppsignalTracing)
  mutation(Types::MutationType)
  query(Types::QueryType)

  class << self
    def model_type_map
      @model_class_map ||= {
        ::Dropzone => ::Types::DropzoneType,
        ::DropzoneUser => ::Types::DropzoneUserType,
        ::Extra => ::Types::ExtraType,
        ::Federation => ::Types::FederationType,
        ::FormTemplate => ::Types::FormTemplateType,
        ::License => ::Types::LicenseType,
        ::LicensedJumpType => ::Types::LicensedJumpTypeType,
        ::Load => ::Types::LoadType,
        ::Notification => ::Types::NotificationType,
        ::Order => ::Types::OrderType,
        ::Permission => ::Types::Access::PermissionType,
        ::Plane => ::Types::PlaneType,
        ::Receipt => ::Types::ReceiptType,
        ::Rig => ::Types::RigType,
        ::RigInspection => ::Types::RigInspectionType,
        ::Slot => ::Types::SlotType,
        ::TicketType => ::Types::TicketTypeType,
        ::Transaction => ::Types::TransactionType,
        ::User => ::Types::UserType,
        ::UserRole => ::Types::UserRoleType,
        ::UserFederation => ::Types::UserFederationType,
        ::WeatherCondition => ::Types::WeatherConditionType,
        nil => ::Types::BaseObject,
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
