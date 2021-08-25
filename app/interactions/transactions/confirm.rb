# frozen_string_literal: true

require "active_interaction"

class Transactions::Confirm < ActiveInteraction::Base
  include ActiveInteraction::Extras::Transaction
  run_in_transaction!
  record :receipt

  validates :receipt, presence: true

  def execute
    return unless receipt.transactions.where(status: :reserved).exists?

    receipt.transactions.each do |transaction|
      transaction.update(status: :completed)
    end

    receipt.order.update(state: :completed) unless receipt.order.transactions.where.not(status: :completed).exists?
    receipt
  end
end
