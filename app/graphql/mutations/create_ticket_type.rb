module Mutations
  class CreateTicketType < Mutations::BaseMutation
    field :ticket_type, Types::TicketTypeType, null: true

    argument :attributes, Types::Input::TicketTypeInput, required: true

    def resolve(attributes:)
      model = TicketType.new(attributes.to_h.except("extra_ids"))

      if model.save
        unless attributes[:ticket_type_ids].nil?
          ::TicketTypeExtra.create(
            Extra.where(id: attributes[:ticket_type_ids]).map do |e|
              { extra_id: e.id, ticket_type_id: model.id }
            end
          )
        end
        { ticket_type: model }
      else
        model_errors!(model)
      end
    end
  end
end