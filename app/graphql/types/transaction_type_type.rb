# frozen_string_literal: true

module Types
  class TransactionTypeType < Types::BaseEnum
    Transaction.transaction_types.keys.each do |type|
      value type
    end
  end
end
