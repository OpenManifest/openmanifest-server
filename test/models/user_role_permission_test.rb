# frozen_string_literal: true

# == Schema Information
#
# Table name: user_role_permissions
#
#  id            :integer          not null, primary key
#  permission_id :integer          not null
#  user_role_id  :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
require "test_helper"

class UserRolePermissionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
