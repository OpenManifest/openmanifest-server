# frozen_string_literal: true

module Types
  class RigType < Types::BaseObject
    implements Types::AnyResourceType
    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    field :make, String, null: true
    field :model, String, null: true
    field :serial, String, null: true
    field :canopy_size, Int, null: true
    field :pack_value, Int, null: true
    field :rig_type, String, null: true
    field :repack_expires_at, Int, null: true
    field :maintained_at, Int, null: true
    field :is_public, Boolean, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :dropzone, Types::DropzoneType, null: true
    field :owner, Types::UserType, null: true, method: :user
    field :packing_card, String, null: true
    def packing_card
      return nil unless object.packing_card.attached?
      Rails.application.routes.url_helpers.url_for(object.packing_card)
    end

    field :rig_inspections, Types::RigInspectionType, null: true do
      argument :dropzone_id, GraphQL::Types::ID, required: true
    end
    def rig_inspections(dropzone_id: nil)
      dropzone = Dropzone.find_by(id: dropzone_id)
      return nil unless dropzone
      rig.rig_inspections.at_dropzone(dropzone)
    end
  end
end
