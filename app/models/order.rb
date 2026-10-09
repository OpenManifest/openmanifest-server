# frozen_string_literal: true

# == Schema Information
#
# Table name: orders
#
#  id           :bigint           not null, primary key
#  dropzone_id  :bigint           not null
#  seller_type  :string           not null
#  seller_id    :bigint           not null
#  buyer_type   :string           not null
#  buyer_id     :bigint           not null
#  item_type    :string           not null
#  item_id      :bigint           not null
#  order_number :integer          default(1), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class Order < ApplicationRecord
  include MoneyAttributes

  money :amount
  belongs_to :dropzone
  belongs_to :seller, polymorphic: true
  belongs_to :buyer, polymorphic: true
  belongs_to :item, polymorphic: true, optional: true

  has_many :receipts
  has_many :transactions, through: :receipts

  before_create :set_order_number

  enum :state, { :pending => 0, :completed => 1, :refunded => 2, :cancelled => 3 }

  scope :at_dropzone, ->(dropzone) { where(dropzone: dropzone) }

  # Order numbers count up per dropzone. The dropzone row is locked until the end of the transaction (every purchase
  # updates it anyway), so concurrent orders get different numbers; the unique index backs this up.
  def set_order_number
    Dropzone.where(id: dropzone_id).lock.pick(:id)
    current_max = Order.at_dropzone(dropzone).maximum(:order_number) || 0
    assign_attributes(order_number: current_max + 1)
  end
end
