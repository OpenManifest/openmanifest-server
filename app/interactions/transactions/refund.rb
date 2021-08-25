# frozen_string_literal: true

require "active_interaction"

class Transactions::Refund < ActiveInteraction::Base
  include ActiveInteraction::Extras::Transaction
  run_in_transaction!

  record :order

  validates :order, presence: true

  def execute
    receipt = order.receipts.last
    # Create a receipt
    new_receipt = Receipt.create(
      amount_cents: receipt.amount_cents * -1,
      order: receipt.order
    )

    errors.merge!(new_receipt.errors) unless new_receipt.valid?

    receipt.transactions.where(status: [:completed, :reserved]).each do |transaction|
      # Create reversed transaction
      transaction = Transaction.create(
        sender: transaction.sender,
        receiver: transaction.receiver,
        amount: transaction.amount * -1,
        message: "Refunded",
        receipt: new_receipt,
        transaction_type: :refund,
        status: :reserved,
      )
      errors.merge!(transaction.errors) if transaction.errors.any?
    end

    receipt.order.buyer.increment!(:credits, receipt.amount_cents / 100)
    receipt.order.seller.decrement!(:credits, receipt.amount_cents / 100)

    # Confirm the transaction and charge
    compose(Transactions::Confirm, receipt: receipt.reload)
    compose(Transactions::Confirm, receipt: new_receipt.reload)
    new_receipt.order.update(state: :refunded)
    new_receipt.order.reload
  end
end
