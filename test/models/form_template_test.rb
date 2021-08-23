# frozen_string_literal: true

# == Schema Information
#
# Table name: form_templates
#
#  id            :bigint           not null, primary key
#  name          :string
#  definition    :text
#  dropzone_id   :bigint
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  created_by_id :bigint
#  updated_by_id :bigint
#
require "test_helper"

class FormTemplateTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
