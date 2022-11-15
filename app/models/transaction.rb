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
class Transaction < ApplicationRecord
  belongs_to :receipt
  has_one :order, through: :receipt
  has_one :item, through: :order

  belongs_to :sender, polymorphic: true
  belongs_to :receiver, polymorphic: true

  has_many :notifications, as: :resource

  after_create :notify!

  enum status: { :reserved => 0, :completed => 1, :cancelled => 2 }

  enum transaction_type: { :purchase => 0, :sale => 1, :deposit => 2, :withdrawal => 3, :refund => 4 }

  scope :completed, -> { where(status: :completed) }
  scope :reserved,  -> { where(status: :reserved) }
  scope :cancelled, -> { where(status: :cancelled) }

  def notify!
    case status
    when "deposit"
      Notification.create(
        received_by: dropzone_user,
        message: "#{amount} has been credited to your account",
        type: :credits_updated,
        resource: self
      )
    when "refunded"
      Notification.create(
        received_by: dropzone_user,
        message: "#{amount} has been credited to your account",
        type: :credits_updated,
        resource: self
      )
    when "paid"
      Notification.create(
        received_by: dropzone_user,
        message: "Payment of $#{amount} confirmed",
        type: :credits_updated,
        resource: self
      )
    when "withdrawal"
      Notification.create(
        received_by: dropzone_user,
        message: "$#{amount} has been taken out of your account",
        type: :credits_updated,
        resource: self
      )
    end
  end
end
