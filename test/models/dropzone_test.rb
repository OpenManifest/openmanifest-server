# frozen_string_literal: true

# == Schema Information
#
# Table name: dropzones
#
#  id                         :integer          not null, primary key
#  name                       :string
#  federation_id              :integer
#  lat                        :float
#  lng                        :float
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  is_public                  :boolean
#  primary_color              :string
#  secondary_color            :string
#  is_credit_system_enabled   :boolean          default(FALSE)
#  rig_inspection_template_id :integer
#  image                      :string
#  time_zone                  :string           default("Australia/Brisbane")
#
require "test_helper"

class DropzoneTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
