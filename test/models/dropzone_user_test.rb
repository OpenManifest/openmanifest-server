# frozen_string_literal: true

# == Schema Information
#
# Table name: dropzone_users
#
#  id           :integer          not null, primary key
#  user_id      :integer
#  dropzone_id  :integer          not null
#  credits      :float
#  expires_at   :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_role_id :integer          not null
#  ghost_id     :integer
#
require "test_helper"

class DropzoneUserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
