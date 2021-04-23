# frozen_string_literal: true

# == Schema Information
#
# Table name: dropzones
#
#  id                       :integer          not null, primary key
#  name                     :string
#  federation_id            :integer
#  lat                      :float
#  lng                      :float
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  is_public                :boolean
#  primary_color            :string
#  secondary_color          :string
#  checklist_id             :integer
#  is_credit_system_enabled :boolean          default(FALSE)
#
require "test_helper"

class DropzoneTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
