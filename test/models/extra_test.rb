# frozen_string_literal: true

# == Schema Information
#
# Table name: extras
#
#  id          :bigint           not null, primary key
#  cost        :float
#  name        :string
#  dropzone_id :bigint           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  is_deleted  :boolean          default(FALSE)
#
require "test_helper"

class ExtraTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
