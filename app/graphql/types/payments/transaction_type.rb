# frozen_string_literal: true

module Types::Payments
  class TransactionType < Types::Base::Enum
    graphql_name 'TransactionType'
    ::Transaction.transaction_types.each_key do |type|
      value type
    end
  end
end
