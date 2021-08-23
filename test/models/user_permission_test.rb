# frozen_string_literal: true

# == Schema Information
#
# Table name: user_permissions
#
#  id               :bigint           not null, primary key
#  permission_id    :bigint           not null
#  dropzone_user_id :bigint           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
require "test_helper"

class UserPermissionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
