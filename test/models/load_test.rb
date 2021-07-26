# frozen_string_literal: true

# == Schema Information
#
# Table name: loads
#
#  id             :integer          not null, primary key
#  dispatch_at    :datetime
#  has_landed     :boolean
#  plane_id       :integer          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  name           :string
#  max_slots      :integer          default(0)
#  is_open        :boolean
#  gca_id         :integer
#  load_master_id :integer
#  pilot_id       :integer
#  state          :integer
#  load_number    :integer
#
require "test_helper"

class LoadTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
