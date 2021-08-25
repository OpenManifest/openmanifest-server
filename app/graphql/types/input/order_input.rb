# frozen_string_literal: true

module Types
  module Input
    class OrderInput < Types::BaseInputObject
      argument :title, String, required: false
      argument :seller, Types::Input::WalletInput,
               required: true,
               description: 'Any sales peer, e.g DropzoneUser or Dropzone'
      argument :buyer, Types::Input::WalletInput,
               required: true,
               description: 'Any buyer peer, e.g DropzoneUser or Dropzone'
      argument :amount, Int, required: true,
                             description: 'Total amount of the order'
      argument :sellable_item, Types::Input::SellableItemInput, required: false
      argument :dropzone_id, Integer, required: true
    end
  end
end
