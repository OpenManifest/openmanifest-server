# frozen_string_literal: true

module Types::Payments
  class TransactionStatus < Types::Base::Enum
    ::Transaction.statuses.each_key do |type|
      value type
    end
  end
end
