# == Schema Information
#
# Table name: master_logs
#
#  id          :integer          not null, primary key
#  dzso_id     :integer
#  dropzone_id :integer          not null
#  notes       :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require "test_helper"

class MasterLogTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
