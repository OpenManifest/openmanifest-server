# frozen_string_literal: true

module Types
  module Input
    class TransactionInput < Types::BaseInputObject
      argument :status, String, required: false
      argument :message, String, required: false
      argument :dropzone_user_id, Int, required: false
      argument :amount, Float, required: false
    end
  end
end
