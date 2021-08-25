# frozen_string_literal: true

module Types
  class TicketTypeType < Types::BaseObject
    implements Types::AnyResourceType
    implements Types::SellableItemType
    def title
      "#{object.name} ticket"
    end

    field :id, GraphQL::Types::ID, null: false
    field :currency, String, null: true
    field :dropzone, Types::DropzoneType, null: true
    field :cost, Float, null: false
    field :name, String, null: true
    field :altitude, Int, null: true
    field :allow_manifesting_self, Boolean, null: true
    field :is_tandem, Boolean, null: true
    field :created_at, Int, null: false
    field :updated_at, Int, null: false
    field :extras, [Types::ExtraType], null: false
  end
end
