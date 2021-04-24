class Transaction < ApplicationRecord
  belongs_to :dropzone_user
  belongs_to :slot, optional: true

  after_create :update_credits

  enum status: [
    :paid,
    :refunded,
    :deposit,
    :withdrawal
  ]

  def update_credits
    dropzone_user.credits + amount
  end
end
