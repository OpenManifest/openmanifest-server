# frozen_string_literal: true

# == Schema Information
#
# Table name: slot_extras
#
#  id         :bigint           not null, primary key
#  slot_id    :bigint           not null
#  extra_id   :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require "test_helper"

class SlotExtraTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
