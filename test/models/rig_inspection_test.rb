# frozen_string_literal: true

# == Schema Information
#
# Table name: rig_inspections
#
#  id               :integer          not null, primary key
#  form_template_id :integer          not null
#  dropzone_user_id :integer          not null
#  rig_id           :integer          not null
#  is_ok            :boolean          default(FALSE), not null
#  definition       :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  inspected_by_id  :integer
#
require "test_helper"

class RigInspectionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
