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
        case arguments[:type].camelize
        when TicketType.name
          TicketType.find(arguments[:id])
        when Pack.name
          Pack.find(arguments[:id])
        when Extra.name
          Extra.find(arguments[:id])
        when Slot.name
          Slot.find(arguments[:id])
        else
          nil
        end
      end
    end
  end
end
