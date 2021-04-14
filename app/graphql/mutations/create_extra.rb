module Mutations
  class CreateExtra < Mutations::BaseMutation
    field :extra, Types::ExtraType, null: true

    argument :attributes, Types::Input::ExtraInput, required: true
    argument :id, Int, required: false

    def resolve(attributes:, id: nil)
      model = find_or_build_model(id)
      model.attributes = attributes.to_h

      if model.save
        unless attributes[:extra_ids].nil?
          ::TicketTypeExtra.create(
            Extra.where(id: attributes[:extra_ids]).map do |e|
              { extra: model, ticket_type_id: e }
            end
          )
        end

        {extra: model}
      else
        {errors: model.errors.full_messages}
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