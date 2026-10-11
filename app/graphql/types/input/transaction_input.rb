# frozen_string_literal: true

module Types
  module Input
    class TransactionInput < Types::Base::Input
      argument :status, String, required: false
      argument :message, String, required: false
      argument :dropzone_user_id, Int, required: false
      money_argument :amount
    end
  end
end
