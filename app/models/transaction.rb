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
  include MoneyAttributes

  money :amount
  belongs_to :receipt
  has_one :order, through: :receipt
  has_one :item, through: :order

  belongs_to :sender, polymorphic: true
  belongs_to :receiver, polymorphic: true

  has_many :notifications, as: :resource

  after_save :notify!, if: -> { saved_change_to_status? && completed? }

  enum :status, { :reserved => 0, :completed => 1, :cancelled => 2 }

  enum :transaction_type, { :purchase => 0, :sale => 1, :deposit => 2, :withdrawal => 3, :refund => 4 }

  scope :completed, -> { where(status: :completed) }
  scope :reserved,  -> { where(status: :reserved) }
  scope :cancelled, -> { where(status: :cancelled) }

  # Tells the member whose account the money moved to or from, once the transaction is completed (a purchase is
  # reserved when the jumper is manifested and completed when the load lands). Transactions of the dropzone itself, the
  # other half of every sale, notify nobody.
  def notify!
    return unless receiver.is_a?(DropzoneUser)

    Notification.create!(
      received_by: receiver,
      message: notification_message,
      notification_type: :credits_updated,
      resource: self
    )
  end

  private

  def notification_message
    value = Money.new(amount_cents.to_i).abs.to_s
    case transaction_type
    when "purchase" then "Payment of #{value} confirmed"
    when "withdrawal" then "#{value} has been taken out of your account"
    else "#{value} has been credited to your account"
    end
  end
end
