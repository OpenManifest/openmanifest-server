# == Schema Information
#
# Table name: form_templates
#
#  id            :integer          not null, primary key
#  name          :string
#  definition    :text
#  dropzone_id   :integer
#  created_by_id :integer          not null
#  updated_by_id :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class FormTemplate < ApplicationRecord
  belongs_to :dropzone, optional: true
  belongs_to :created_by, class_name: "User"
  belongs_to :updated_by, class_name: "User"
end
