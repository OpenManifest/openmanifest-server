module Types
  class ExtraType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    field :ticket_types, [Types::TicketTypeType], null: false
    field :cost, Int, null: false
    field :created_at, Int, null: false
    field :updated_at, Int, null: false

  end
end