# == Schema Information
#
# Table name: licenses
#
#  id            :integer          not null, primary key
#  name          :string
#  federation_id :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
require "test_helper"

class LicenseTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
