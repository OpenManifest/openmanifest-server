# frozen_string_literal: true

# == Schema Information
#
# Table name: licensed_jump_types
#
#  id           :integer          not null, primary key
#  license_id   :integer          not null
#  jump_type_id :integer          not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
require "test_helper"

class LicensedJumpTypeTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
