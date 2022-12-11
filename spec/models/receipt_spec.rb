# frozen_string_literal: true

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
require "rails_helper"

RSpec.describe Receipt do
  pending "add some examples to (or delete) #{__FILE__}"
end
