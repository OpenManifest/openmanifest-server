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
#
class Transaction < ApplicationRecord
  belongs_to :dropzone_user
  belongs_to :slot, optional: true

  after_create :update_credits

  enum status: [
    :paid,
    :refunded,
    :deposit,
    :withdrawal,
    :reserved,
  ]

  def update_credits
    DropzoneUser.update_counters(
      dropzone_user_id,
      credits: amount
    )
  end
end
