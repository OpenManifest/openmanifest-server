# frozen_string_literal: true

module Types
  module Input
    class OrderInput < Types::BaseInputObject
      argument :title, String, required: false
      argument :seller, ID,
               required: true,
               description: "Any sales peer, e.g DropzoneUser or Dropzone",
               prepare: -> (value, ctx) { ::DzSchema.object_from_id(value, ctx) }

      argument :buyer, ID,
               required: true,
               description: "Any buyer peer, e.g DropzoneUser or Dropzone",
               prepare: -> (value, ctx) { ::DzSchema.object_from_id(value, ctx) }

      argument :sellable_item, ID,
               description: "Item to attach to order",
               required: false,
               prepare: -> (value, ctx) { ::DzSchema.object_from_id(value, ctx) }
      argument :amount, Float,
               required: true,
               description: "Total amount of the order"
      argument :dropzone, ID, required: true,
               prepare: -> (id, ctx) { ::Dropzone.find_by(id: id) }
    end
  end
end
