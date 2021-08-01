# frozen_string_literal: true

# == Schema Information
#
# Table name: form_templates
#
#  id                :integer          not null, primary key
#  name              :string
#  definition        :text
#  dropzone_id       :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  dropzone_users_id :integer
#  created_by_id     :integer
#  updated_by_id     :integer
#
require "test_helper"

class FormTemplateTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
