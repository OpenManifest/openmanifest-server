# frozen_string_literal: true

# == Schema Information
#
# Table name: checklists
#
#  id            :integer          not null, primary key
#  name          :string
#  created_by_id :integer          not null
#  updated_by_id :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
require "test_helper"

class ChecklistTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
