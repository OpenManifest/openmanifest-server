# frozen_string_literal: true

# == Schema Information
#
# Table name: rig_inspections
#
#  id               :bigint           not null, primary key
#  form_template_id :bigint           not null
#  dropzone_user_id :bigint           not null
#  rig_id           :bigint           not null
#  is_ok            :boolean          default(FALSE), not null
#  definition       :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  inspected_by_id  :bigint
#
require "test_helper"

class RigInspectionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
