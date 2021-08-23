# frozen_string_literal: true

# == Schema Information
#
# Table name: planes
#
#  id                     :bigint           not null, primary key
#  name                   :string
#  min_slots              :integer
#  max_slots              :integer
#  hours                  :integer
#  next_maintenance_hours :integer
#  registration           :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  dropzone_id            :bigint           not null
#  is_deleted             :boolean          default(FALSE)
#
require "test_helper"

class PlaneTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
