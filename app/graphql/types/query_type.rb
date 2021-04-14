module Types
  class QueryType < Types::BaseObject
    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField

    field :image, String, null: true,
    description: "Load base64 images as graphql" do
      argument :id, Int, required: true
    end
    def image(id)
      blob = ActiveStorage::Blod.find(id)
      blob.download
    end

    field :federations, [Types::FederationType], null: false,
    description: "Available federations"
    def federations
      Federation.all
    end

    field :dropzones, Types::DropzoneType.connection_type,
    null: false, description: "Get all available dropzones"
    def dropzones
      Dropzone.all.distinct
    end

    field :dropzone, Types::DropzoneType,
    null: false, description: "Get dropzone details" do
      argument :id, Int, required: true
    end
    def dropzone(id:)
      Dropzone.includes(loads: :slots).find(id)
    end

    field :loads, Types::LoadType.connection_type,
    null: false, description: "Get loads" do
      argument :dropzone_id, Int, required: true
      argument :earliest_timestamp, Int, required: false
    end
    def loads(dropzone_id:, earliest_timestamp:)
      dz = Dropzone.includes(loads: :slots).find(id)
      loads = dz.loads
      loads = loads.where("created_at > ?", earliest_timestamp) unless earliest_timestamp.nil?
      loads.order(created_at: :desc)
    end
    

    field :planes, [Types::PlaneType],
    null: false, description: "Get planes from a dropzone" do
      argument :dropzone_id, Int, required: true
    end
    def planes(dropzone_id:)
      Plane.where(dropzone_id: dropzone_id).order(name: :asc)
    end

    field :ticket_types, [Types::TicketTypeType],
    null: false, description: "Get ticket types for a dropzone" do
      argument :dropzone_id, Int, required: true
    end
    def ticket_types(dropzone_id:)
      TicketType.includes(ticket_type_extras: :extra).where(dropzone_id: dropzone_id).order(name: :asc)
    end

    field :extras, [Types::ExtraType],
    null: false, description: "Get ticket addons for a dropzone" do
      argument :dropzone_id, Int, required: true
    end
    def extras(dropzone_id:)
      Extra.includes(ticket_type_extras: :ticket_type).where(dropzone_id: dropzone_id).order(name: :asc)
    end
  end
end
