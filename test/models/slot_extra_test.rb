# == Schema Information
#
# Table name: slot_extras
#
#  id         :integer          not null, primary key
#  slot_id    :integer          not null
#  extra_id   :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require "test_helper"

class SlotExtraTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
