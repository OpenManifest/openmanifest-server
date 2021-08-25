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
require 'rails_helper'

RSpec.describe Order, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
