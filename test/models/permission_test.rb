# frozen_string_literal: true

# == Schema Information
#
# Table name: permissions
#
#  id           :integer          not null, primary key
#  name         :integer
#  user_role_id :integer          not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
require "test_helper"

class PermissionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
