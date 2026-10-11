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

    # Credits move between the dropzone and its members (BUG-008):
    # - both parties must be the order's dropzone or a member of it, whatever GlobalID the client sent
    # - transfers between two members are disabled (decision D8, see P6.7)
    # - the dropzone paying or charging a member needs createUserTransaction; a member may only pay the dropzone from
    #   their own credits
    def authorized?(attributes: nil, id: nil)
      dropzone = attributes[:dropzone]
      return refuse("Dropzone not found") if dropzone.blank?

      membership = DropzoneUser.membership(dropzone, context[:current_resource])
      return refuse("You are not a member of this dropzone") unless membership
      return refuse("Amount must be positive") unless attributes[:amount] > 0

      buyer = attributes[:buyer]
      seller = attributes[:seller]
      return refuse("The buyer and the seller must be the dropzone or its members") unless [buyer, seller].all? { |party| party_of?(party, dropzone) }
      return refuse("Transfers between members are disabled") if buyer.is_a?(::DropzoneUser) && seller.is_a?(::DropzoneUser)
      return refuse("The dropzone cannot pay itself") if buyer.is_a?(::Dropzone) && seller.is_a?(::Dropzone)

      return true if membership.can?(:createUserTransaction)
      return true if buyer == membership && seller.is_a?(::Dropzone) && can_afford?(buyer, attributes[:amount])

      refuse("You don't have permissions to create this order")
    end

    private

    def party_of?(party, dropzone)
      case party
      when ::Dropzone then party.id == dropzone.id
      when ::DropzoneUser then party.dropzone_id == dropzone.id && party.kept?
      else false
      end
    end

    def can_afford?(buyer, amount)
      buyer.dropzone.allow_negative_credits? || (buyer.credits || 0) >= amount
    end

    def refuse(message)
      [false, { errors: [message] }]
    end
  end
end
