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
FactoryBot.define do
  factory :order do
    dropzone { nil }
  end
end
