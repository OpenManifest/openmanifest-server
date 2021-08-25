# frozen_string_literal: true

# == Schema Information
#
# Table name: licenses
#
#  id            :bigint           not null, primary key
#  name          :string
#  federation_id :bigint           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
require "test_helper"

class LicenseTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
