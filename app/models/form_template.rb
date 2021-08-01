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
class FormTemplate < ApplicationRecord
  belongs_to :dropzone, optional: true
  belongs_to :created_by, class_name: "DropzoneUser"
  belongs_to :updated_by, class_name: "DropzoneUser"
end
