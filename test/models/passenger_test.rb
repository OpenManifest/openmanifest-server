# frozen_string_literal: true

# == Schema Information
#
# Table name: passengers
#
#  id          :integer          not null, primary key
#  name        :string
#  exit_weight :float
#  dropzone_id :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require "test_helper"

class PassengerTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
