module Types
  class TicketTypeType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :currency, String, null: true
    field :cost, Float, null: true
    field :name, String, null: true
    field :altitude, Int, null: true
    field :allow_manifesting_self, Boolean, null: true
    field :created_at, Int, null: false
    field :updated_at, Int, null: false
    field :extras, [Types::ExtraType], null: false
  end
end