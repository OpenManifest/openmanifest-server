# frozen_string_literal: true

module Mutations
  class UpdateTicketType < Mutations::BaseMutation
    field :ticket_type, Types::TicketTypeType, null: true

    argument :id, Int, required: true
    argument :attributes, Types::Input::TicketTypeInput, required: true

    def resolve(attributes:, id:)
      model = TicketType.find(id)

      if model.update(attributes.to_h)
        unless attributes[:extra_ids].nil?
          ::TicketTypeExtra.includes(:extra, :ticket_type).where(
            extras: { dropzone_id: attributes[:dropzone_id] }
          ).where.not(
            extras: { id: attributes[:extra_ids] }
          ).destroy_all

          attributes[:extra_ids] - TicketTypeExtra.where(
            extra_id: attributes[:extra_ids]
          ).pluck(:extra_id).to_a do |i|
            ::TicketTypeExtra.create(extra_id: i, ticket_type: model)
          end
        end

        { ticket_type: model }
      else
        model_errors!(model)
      end
    end
  end
end
