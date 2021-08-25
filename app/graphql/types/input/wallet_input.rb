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
        case arguments[:type].camelize
        when DropzoneUser.name
          DropzoneUser.find(arguments[:id])
        when Dropzone.name
          Dropzone.find(arguments[:id])
        else
          nil
        end
      end
    end
  end
end
