# frozen_string_literal: true

# == Schema Information
#
# Table name: checklist_values
#
#  id                :integer          not null, primary key
#  checklist_item_id :integer          not null
#  created_by_id     :integer          not null
#  updated_by_id     :integer          not null
#  value             :text             not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
require "test_helper"

class ChecklistValueTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
