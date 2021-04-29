# == Schema Information
#
# Table name: rig_inspections
#
#  id               :integer          not null, primary key
#  form_template_id :integer          not null
#  inspected_by_id  :integer          not null
#  dropzone_user_id :integer          not null
#  rig_id           :integer          not null
#  is_ok            :boolean          default(FALSE), not null
#  definition       :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
class RigInspection < ApplicationRecord
  belongs_to :form_template
  belongs_to :inspected_by, class_name: "User"
  belongs_to :rig

  def self.default_form
    [{
      label: "Three-rings routed correctly?",
      valueType: "boolean",
      value: nil,
    }, {
      label: "Reserve canopy size",
      valueType: "integer",
      value: nil
    }, {
      label: "RSL clip attached correctly?",
      valueType: "boolean",
      value: nil
    }, {
      label: "Home dropzone",
      valueType: "string",
      value: nil
    }]
  end
end
