# == Schema Information
#
# Table name: extras
#
#  id          :integer          not null, primary key
#  cost        :float
#  name        :string
#  dropzone_id :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require "test_helper"

class ExtraTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
