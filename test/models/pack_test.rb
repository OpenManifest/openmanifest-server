# frozen_string_literal: true

# == Schema Information
#
# Table name: packs
#
#  id         :integer          not null, primary key
#  rig_id     :integer          not null
#  user_id    :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require "test_helper"

class PackTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
