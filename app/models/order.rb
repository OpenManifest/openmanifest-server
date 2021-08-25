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
  belongs_to :dropzone
  belongs_to :seller, polymorphic: true
  belongs_to :buyer, polymorphic: true
  belongs_to :item, polymorphic: true, optional: true

  has_many :receipts
  has_many :transactions, through: :receipts

  before_create :set_order_number

  enum state: [
    :pending,
    :completed,
    :refunded,
    :cancelled
  ]

  scope :at_dropzone, -> (dropzone) { where(dropzone: dropzone) }

  def set_order_number
    current_max = Order.at_dropzone(dropzone).maximum(:order_number) || 0
    assign_attributes(order_number: current_max + 1)
  end
end
