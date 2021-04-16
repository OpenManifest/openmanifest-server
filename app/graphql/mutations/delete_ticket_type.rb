# frozen_string_literal: true

module Mutations
  class DeleteTicketType < Mutations::BaseMutation
    field :ticket_type, Types::TicketTypeType, null: true

    argument :id, Int, required: true

    def resolve(id:)
      model = TicketType.find(id)

      model.destroy
      { ticket_type: model }
    end
  end
end
