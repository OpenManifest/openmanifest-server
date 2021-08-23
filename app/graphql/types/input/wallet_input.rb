# frozen_string_literal: true

module Types
  module Input
    class WalletInput < Types::BaseInputObject
      argument :type, Types::WalletableTypes,
               required: true,
               description: 'Any model with an account, e.g DropzoneUser or Dropzone'
      argument :id, ID, required: true,
               description: 'ID of the record'

      def to_record
        case object[:type].camelize
        when DropzoneUser.name
          DropzoneUser.find(object[:id])
        when Dropzone.name
          Dropzone.find(object[:id])
        else
          nil
        end
      end
    end
  end
end
