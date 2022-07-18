# frozen_string_literal: true

module Mutations::Payments
  class CreateOrder < Mutations::BaseMutation
    include Types::InteractionMutationInterface
    field :order, Types::OrderType, null: true
    argument :attributes, Types::Input::OrderInput, required: true

    def resolve(attributes:, id: nil)
      mutate(
        ::Transactions::CreateOrder,
        :order,
        title: attributes[:title],
        amount: attributes[:amount],
        seller: attributes[:seller].to_record,
        buyer: attributes[:buyer].to_record,
        dropzone: Dropzone.find(attributes[:dropzone_id]),
        access_context: access_context_for(attributes[:dropzone_id]),
      )
    end

    def authorized?(attributes: nil, id: nil)
      current_user = DropzoneUser.find_by(user_id: context[:current_resource].id, dropzone: attributes[:dropzone_id])
      seller = attributes[:seller].to_record
      buyer = attributes[:buyer].to_record
      amount = attributes[:amount]
      is_peer_to_peer = seller.is_a?(DropzoneUser) && buyer.is_a?(DropzoneUser)

      return false, { errors: ["Amount must be positive"] } unless amount > 0

      # Users are allowed to send money to other users by default
      # If the user is the buyer, and the amount is positive
      return true if current_user == buyer && is_peer_to_peer
      return true if current_user.can?(:createUserTransaction)

      [false, {
        errors: [
          "You don't have permissions to create ticket addons"
        ]
      }]
    end
  end
end
