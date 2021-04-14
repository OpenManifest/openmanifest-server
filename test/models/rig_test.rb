# == Schema Information
#
# Table name: rigs
#
#  id                :integer          not null, primary key
#  make              :string
#  model             :string
#  serial            :string
#  pack_value        :integer
#  repack_expires_at :datetime
#  maintained_at     :datetime
#  user_id           :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
require "test_helper"

class RigTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
