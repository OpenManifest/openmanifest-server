# frozen_string_literal: true

# == Schema Information
#
# Table name: transactions
#
#  id               :bigint           not null, primary key
#  status           :integer
#  amount           :float
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  message          :string
#  sender_type      :string           not null
#  sender_id        :bigint           not null
#  receiver_type    :string           not null
#  receiver_id      :bigint           not null
#  receipt_id       :bigint           not null
#  transaction_type :integer
#
require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
