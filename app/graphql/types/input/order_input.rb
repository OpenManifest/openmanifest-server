# frozen_string_literal: true

module Types
  module Input
    class OrderInput < Types::Base::Input
      argument :title, String, required: false
      argument :seller, ID,
               required: true,
               description: "Any sales peer, e.g Membership or Operator",
               prepare: -> (value, ctx) { ::DzSchema.object_from_id(value, ctx) }

      argument :buyer, ID,
               required: true,
               description: "Any buyer peer, e.g Membership or Operator",
               prepare: -> (value, ctx) { ::DzSchema.object_from_id(value, ctx) }

      argument :sellable_item, ID,
               description: "Item to attach to order",
               required: false,
               prepare: -> (value, ctx) { ::DzSchema.object_from_id(value, ctx) }
      money_argument :amount, description: "Total amount of the order"
      argument :operator, ID, required: true,
                              prepare: -> (id, ctx) { ::Operator.find_by(id: id) }
    end
  end
end
