# == Schema Information
#
# Table name: receipts
#
#  id           :bigint           not null, primary key
#  amount_cents :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  order_id     :bigint
#
class Receipt < ApplicationRecord
  belongs_to :order
  has_many :transactions
end
