# frozen_string_literal: true

class Transactions::Refund < ApplicationInteraction
  record :order
  validates :order, presence: true

  steps :create_receipt,
        :create_transactions,
        :update_credits,
        :confirm_order,
        :order

  # Create events
  success do
   compose(
     ::Activity::CreateEvent,
     access_level: :system,
     access_context: access_context,
     resource: order,
     action: :updated,
     dropzone: access_context.dropzone,
     created_by: access_context.subject,
     message: "Order ##{order.id} was refunded"
   )
 end

  error do
    compose(
      ::Activity::CreateEvent,
      access_level: :system,
      level: :error,
      access_context: access_context,
      resource: order,
      action: :updated,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "Failed to refund Order ##{order.id}",
      details: errors.full_messages.join(", ")
    )
  end

  def create_receipt
    @receipt = order.receipts.last
    # Create a receipt
    @new_receipt = Receipt.create(
      amount_cents: @receipt.amount_cents * -1,
      order: @receipt.order
    )
    errors.merge!(@new_receipt.errors) unless @new_receipt.valid?
  end

  def create_transactions
    @receipt.transactions.where(status: %i[completed reserved]).each do |transaction|
      # Create reversed transaction
      transaction = Transaction.create(
        sender: transaction.sender,
        receiver: transaction.receiver,
        amount: transaction.amount * -1,
        message: "Refunded",
        receipt: @new_receipt,
        transaction_type: :refund,
        status: :reserved
      )
      errors.merge!(transaction.errors) if transaction.errors.any?
    end
  end

  def update_credits
    @receipt.order.buyer.increment!(:credits, @receipt.amount_cents / 100)
    @receipt.order.seller.decrement!(:credits, @receipt.amount_cents / 100)
  end

  def confirm_order
    # Confirm the transaction and charge
    compose(Transactions::Confirm, receipt: @receipt.reload, access_context: access_context)
    compose(Transactions::Confirm, receipt: @new_receipt.reload, access_context: access_context)
    @new_receipt.order.update(state: :refunded)
    @new_receipt.order.reload
  end
end
