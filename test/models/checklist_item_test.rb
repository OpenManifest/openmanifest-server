# frozen_string_literal: true

# == Schema Information
#
# Table name: checklist_items
#
#  id            :integer          not null, primary key
#  checklist_id  :integer          not null
#  created_by_id :integer          not null
#  updated_by_id :integer          not null
#  value_type    :integer
#  is_required   :boolean
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  name          :string
#  description   :text
#
require "test_helper"

class ChecklistItemTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
