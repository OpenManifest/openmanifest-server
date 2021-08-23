# frozen_string_literal: true

module Types
  module Input
    class SellableItemInput < Types::BaseInputObject
      argument :type, Types::SellableItemTypes,
               required: true,
               description: 'Any sales peer, e.g DropzoneUser or Dropzone'
      argument :id, ID, required: true,
               description: 'ID of the record'

      def to_record
        case object[:type].camelize
        when TicketType.name
          TicketType.find(object[:id])
        when Pack.name
          Pack.find(object[:id])
        when Extra.name
          Extra.find(object[:id])
        when Slot.name
          Slot.find(object[:id])
        else
          nil
        end
      end
    end
  end
end
