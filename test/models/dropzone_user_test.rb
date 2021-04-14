# == Schema Information
#
# Table name: dropzone_users
#
#  id          :integer          not null, primary key
#  user_id     :integer          not null
#  dropzone_id :integer          not null
#  role        :integer
#  credits     :float
#  expires_at  :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require "test_helper"

class DropzoneUserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
