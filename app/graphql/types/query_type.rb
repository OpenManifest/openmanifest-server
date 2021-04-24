# frozen_string_literal: true

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
    description: "Available federations", authenticate: false
    def federations
      Federation.all
    end

    field :dropzones, Types::DropzoneType.connection_type, null: false,
    description: "Get all available dropzones"
    def dropzones
      Dropzone.all.distinct
    end

    field :dropzone, Types::DropzoneType, null: false,
    description: "Get dropzone details" do
      argument :id, Int, required: true
    end
    def dropzone(id:)
      Dropzone.includes(loads: :slots).find(id)
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
      Load.includes(:gca, :load_master, :pilot, :plane, slots: :user).find(id)
    end


    field :planes, [Types::PlaneType], null: false,
    description: "Get planes from a dropzone" do
      argument :dropzone_id, Int, required: true
    end
    def planes(dropzone_id:)
      Plane.where(dropzone_id: dropzone_id).order(name: :asc)
    end

    field :ticket_types, [Types::TicketTypeType], null: false,
    description: "Get ticket types for a dropzone" do
      argument :dropzone_id, Int, required: true
      argument :allow_manifesting_self, Boolean, required: false
    end
    def ticket_types(dropzone_id: nil, allow_manifesting_self: nil)
      query = TicketType.includes(ticket_type_extras: :extra).where(dropzone_id: dropzone_id)

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
      Extra.includes(ticket_type_extras: :ticket_type).where(dropzone_id: dropzone_id).order(name: :asc)
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

    field :rigs, [Types::RigType], null: true,
    description: "Get rigs for user or dropzone" do
      argument :user_id, Int, required: false
      argument :dropzone_id, Int, required: false
    end
    def rigs(dropzone_id: nil, user_id: nil)
      query = Rig
      if dropzone_id && context[:current_resource].can?("readRig", dropzone_id: dropzone_id)
        query = query.where(dropzone_id: dropzone_id)
      end

      if user_id
        if context[:current_resource].id == user_id
          query = query.or(
            Rig.where(user_id: user_id)
          )
        elsif dropzone_id && context[:current_resource].can?("readRig", dropzone_id: dropzone_id)
          query = query.or(
            Rig.where(user_id: user_id)
          )
        end
      end

      query
    end
  end
end
