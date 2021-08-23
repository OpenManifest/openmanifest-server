module Types
  class TransactionStatusType < Types::BaseEnum
    Transaction.statuses.keys.each do |type|
      value type
    end
  end
end
