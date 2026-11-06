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
        amount_cents: amount_cents(attributes),
        seller: attributes[:seller],
        buyer: attributes[:buyer],
        operator: attributes[:operator],
        access_context: access_context_for(attributes[:operator]),
      )
    end

    # Credits move between the operator and its members (BUG-008):
    # - both parties must be the order's operator or a member of it, whatever GlobalID the client sent
    # - transfers between two members are disabled (decision D8, see P6.7)
    # - the operator paying or charging a member needs createUserTransaction; a member may only pay the operator from
    #   their own credits
    def authorized?(attributes: nil, id: nil)
      operator = attributes[:operator]
      return refuse("Operator not found") if operator.blank?

      membership = Membership.of(operator, context[:current_resource])
      return refuse("You are not a member of this operator") unless membership
      cents = amount_cents(attributes)
      return refuse("An amount is needed") if cents.nil?
      return refuse("Amount must be positive") unless cents.positive?

      buyer = attributes[:buyer]
      seller = attributes[:seller]
      return refuse("The buyer and the seller must be the operator or its members") unless [buyer, seller].all? { |party| party_of?(party, operator) }
      return refuse("Transfers between members are disabled") if buyer.is_a?(::Membership) && seller.is_a?(::Membership)
      return refuse("The operator cannot pay itself") if buyer.is_a?(::Operator) && seller.is_a?(::Operator)

      return true if membership.can?(:createUserTransaction)
      return true if buyer == membership && seller.is_a?(::Operator) && can_afford?(buyer, cents)

      refuse("You don't have permissions to create this order")
    end

    private

    def party_of?(party, operator)
      case party
      when ::Operator then party.id == operator.id
      when ::Membership then party.operator_id == operator.id && party.kept?
      else false
      end
    end

    def amount_cents(attributes)
      attributes[:amount_cents]
    end

    def can_afford?(buyer, cents)
      buyer.operator.allow_negative_credits? || (buyer.credits_cents || 0) >= cents
    end

    def refuse(message)
      [false, { errors: [message] }]
    end
  end
end
