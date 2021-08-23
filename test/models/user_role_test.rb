# frozen_string_literal: true

# == Schema Information
#
# Table name: user_roles
#
#  id          :bigint           not null, primary key
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  dropzone_id :bigint           not null
#
require "test_helper"

class UserRoleTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
