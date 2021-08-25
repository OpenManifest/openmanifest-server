# frozen_string_literal: true

module Types
  class TransactionStatusType < Types::BaseEnum
    Transaction.statuses.each_key do |type|
      value type
    end
  end
end
