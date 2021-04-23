# frozen_string_literal: true

# == Schema Information
#
# Table name: rig_inspections
#
#  id               :integer          not null, primary key
#  checklist_id     :integer          not null
#  inspected_by_id  :integer          not null
#  rig_id           :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  dropzone_user_id :integer          not null
#
require "test_helper"

class RigInspectionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
