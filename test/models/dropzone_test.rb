# == Schema Information
#
# Table name: dropzones
#
#  id            :integer          not null, primary key
#  name          :string
#  federation_id :integer
#  lat           :float
#  lng           :float
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
require "test_helper"

class DropzoneTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
