# frozen_string_literal: true

require "active_interaction"

class Transactions::Confirm < ApplicationInteraction
  record :receipt
  validates :receipt, presence: true

  steps :complete_transactions,
        :receipt

  # Create events
  success do
    compose(
      ::Activity::CreateEvent,
      access_level: :system,
      access_context: access_context,
      resource: receipt,
      action: :confirmed,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "Order ##{receipt.order.id} has been confirmed and transactions have been completed"
    )
  end

  error do
    compose(
      ::Activity::CreateEvent,
      level: :error,
      access_level: :system,
      access_context: access_context,
      resource: receipt,
      action: :confirmed,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "Order ##{receipt.order.id} failed to confirm",
      details: errors.full_messages.join(", ")
    )
  end

  def complete_transactions
    return unless receipt.transactions.where(status: :reserved).exists?

    receipt.transactions.each do |transaction|
      transaction.update(status: :completed)
    end

    receipt.order.update(state: :completed) unless receipt.order.transactions.where.not(status: :completed).exists?
    receipt
  end
end
