# frozen_string_literal: true

module Mutations
  class UpdateExtra < Mutations::BaseMutation
    field :extra, Types::ExtraType, null: true

    argument :attributes, Types::Input::ExtraInput, required: true
    argument :id, Int, required: false

    def resolve(attributes:, id: nil)
      model = find_or_build_model(id)
      model.attributes = attributes.to_h.except("ticket_type_ids")

      if model.save
        unless attributes[:ticket_type_ids].nil?
          ::TicketTypeExtra.includes(:extra, :ticket_type).where(
            ticket_types: { dropzone_id: attributes[:dropzone_id] }
          ).where.not(
            ticket_types: { id: attributes[:ticket_type_ids] }
          ).destroy_all

          attributes[:ticket_type_ids] - TicketTypeExtra.where(
            ticket_type_id: attributes[:ticket_type_ids]
          ).pluck(:ticket_type_id).to_a do |i|
            ::TicketTypeExtra.create(extra: model, ticket_type_id: i)
          end
        end

        { extra: model }
      else
        { errors: model.errors.full_messages }
      end
    end

    def find_or_build_model(id)
      if id
        Extra.find(id)
      else
        Extra.new
      end
    end
  end
end
