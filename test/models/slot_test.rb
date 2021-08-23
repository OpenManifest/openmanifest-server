# frozen_string_literal: true

# == Schema Information
#
# Table name: slots
#
#  id                :bigint           not null, primary key
#  ticket_type_id    :bigint
#  load_id           :bigint
#  rig_id            :bigint
#  jump_type_id      :bigint
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  exit_weight       :float
#  passenger_id      :bigint
#  is_paid           :boolean
#  transaction_id    :bigint
#  passenger_slot_id :bigint
#  group_number      :integer          default(0), not null
#  dropzone_user_id  :bigint
#
require "test_helper"

class SlotTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
