# frozen_string_literal: true

module Types
  class TransactionStatusType < Types::BaseEnum
    Transaction.statuses.keys.each do |type|
      value type
    end
  end
end
