# == Schema Information
#
# Table name: slots
#
#  id             :integer          not null, primary key
#  user_id        :integer
#  ticket_type_id :integer
#  load_id        :integer
#  rig_id         :integer
#  jump_type_id   :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
require "test_helper"

class SlotTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
