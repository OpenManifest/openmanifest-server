# frozen_string_literal: true

module Types
  class TransactionTypeType < Types::BaseEnum
    Transaction.transaction_types.each_key do |type|
      value type
    end
  end
end
