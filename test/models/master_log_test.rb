# frozen_string_literal: true

# == Schema Information
#
# Table name: master_logs
#
#  id          :bigint           not null, primary key
#  dzso_id     :bigint
#  dropzone_id :bigint           not null
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
