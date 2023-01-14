# frozen_string_literal: true

module Mutations::Payments
  class CreateOrder < Mutations::BaseMutation
    include Types::Interfaces::ActiveInteraction
    field :order, Types::Payments::Order, null: true
    argument :attributes, Types::Input::OrderInput, required: true

    def resolve(attributes:, id: nil)
      mutate(
        ::Transactions::CreateOrder,
        :order,
        title: attributes[:title],
        amount: attributes[:amount],
        seller: attributes[:seller],
        buyer: attributes[:buyer],
        dropzone: attributes[:dropzone],
        access_context: access_context_for(attributes[:dropzone]),
      )
    end

    def authorized?(attributes: nil, id: nil)
      return false if attributes[:dropzone].blank?
      current_user = attributes[:dropzone].dropzone_users.find_by(user: context[:current_resource])
      amount = attributes[:amount]
      is_peer_to_peer = attributes[:seller].is_a?(::DropzoneUser) && attributes[:buyer].is_a?(::DropzoneUser)

      return false, { errors: ["Amount must be positive"] } unless amount > 0

      # Users are allowed to send money to other users by default
      # If the user is the buyer, and the amount is positive
      return true if current_user == attributes[:buyer] && is_peer_to_peer
      return true if current_user.can?(:createUserTransaction)

      [
        false, {
          errors: [
            "You don't have permissions to create this order",
          ],
        },
      ]
    end
  end
end
