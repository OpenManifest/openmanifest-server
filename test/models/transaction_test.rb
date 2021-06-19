# == Schema Information
#
# Table name: transactions
#
#  id               :integer          not null, primary key
#  dropzone_user_id :integer          not null
#  slot_id          :integer
#  status           :integer
#  amount           :float
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  message          :string
#
require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
