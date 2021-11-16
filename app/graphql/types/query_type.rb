# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField
    include Geokit::Geocoders

    field :image, String, null: true,
    description: "Load base64 images as graphql" do
      argument :id, Int, required: true
    end
    def image(id)
      blob = ActiveStorage::Blod.find(id)
      blob.download
    end

    field :federations, [Types::FederationType], null: false,
    description: "Available federations", authenticate: false
    def federations
      Federation.all
    end

    field :dropzones, Types::DropzoneType.connection_type, null: false,
    description: "Get all available dropzones" do
      argument :requested_publication, Boolean, required: false
      argument :is_public, Boolean, required: false
    end
    def dropzones(requested_publication: nil, is_public: nil)
      if is_public || User.moderation_roles[context[:current_resource].moderation_role] < User.moderation_roles["moderator"]
        query = Dropzone.includes(:dropzone_users).where(is_public: true).or(
          Dropzone.includes(:dropzone_users).where(
            dropzone_users: {
              id: context[:current_resource].dropzone_users.includes(:user_role).where(user_role: { name: :owner }).pluck(:id)
            }
          )
        )
      else
        query = Dropzone.all
      end

      query.where!(request_publication: requested_publication) if requested_publication
      query
    end

    field :dropzone, Types::DropzoneType, null: false,
    description: "Get dropzone details" do
      argument :id, Int, required: true
    end
    def dropzone(id:)
      Dropzone.includes(loads: :slots).find(id)
    end

    field :geocode, Types::GeocodedLocationType, null: true,
    description: 'Find location by searching' do
      argument :search, String, required: true
    end
    def geocode(search: '')
      result = GoogleGeocoder.geocode(search)

      if result.success
        { lat: result.lat, lng: result.lng, formatted_string: result.full_address }
      else
        nil
      end
    end

    field :loads, Types::LoadType.connection_type, null: false,
    description: "Get loads" do
      argument :dropzone_id, Int, required: true
      argument :earliest_timestamp, Int, required: false
    end
    def loads(dropzone_id:, earliest_timestamp:)
      dz = Dropzone.includes(loads: :slots).find(id)
      loads = dz.loads
      loads = loads.where("loads.created_at > ?", Time.at(earliest_timestamp)) unless earliest_timestamp.nil?
      loads.order(created_at: :desc)
    end

    field :load, Types::LoadType, null: false,
    description: "Get load by id" do
      argument :id, Int, required: true
    end
    def load(id:)
      Load.includes(:gca, :load_master, :pilot, :plane, slots: :dropzone_user).find(id)
    end


    field :planes, [Types::PlaneType], null: false,
    description: "Get planes from a dropzone" do
      argument :dropzone_id, Int, required: true
    end
    def planes(dropzone_id:)
      Plane.where(dropzone_id: dropzone_id, is_deleted: false).order(name: :asc)
    end

    field :ticket_types, [Types::TicketTypeType], null: false,
    description: "Get ticket types for a dropzone" do
      argument :dropzone_id, Int, required: true
      argument :allow_manifesting_self, Boolean, required: false
    end
    def ticket_types(dropzone_id: nil, allow_manifesting_self: nil)
      query = TicketType.includes(ticket_type_extras: :extra).where(dropzone_id: dropzone_id, is_deleted: false)

      if allow_manifesting_self
        query = query.where(allow_manifesting_self: allow_manifesting_self)
      end

      query.order(name: :asc)
    end

    field :extras, [Types::ExtraType], null: false,
    description: "Get ticket addons for a dropzone" do
      argument :dropzone_id, Int, required: true
    end
    def extras(dropzone_id:)
      Extra.includes(ticket_type_extras: :ticket_type).where(dropzone_id: dropzone_id, is_deleted: false).order(name: :asc)
    end

    field :jump_types, [Types::JumpTypeType], null: false,
    description: "Get all jump types", authenticate: false do
      argument :allowed_for_user_id, Int, required: false
    end
    def jump_types(allowed_for_user_id: nil)
      if allowed_for_user_id
        User.find(allowed_for_user_id).jump_types.order(name: :asc)
      else
        JumpType.order(name: :asc)
      end
    end

    field :licenses, [Types::LicenseType], null: false,
    description: "Get all licenses for a federation", authenticate: false do
      argument :federation_id, Int, required: false
    end
    def licenses(federation_id: nil)
      License.where(federation_id: federation_id).order(name: :asc)
    end
  end
end
