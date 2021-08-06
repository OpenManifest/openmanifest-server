# frozen_string_literal: true

# == Schema Information
#
# Table name: rig_inspections
#
#  id               :integer          not null, primary key
#  form_template_id :integer          not null
#  dropzone_user_id :integer          not null
#  rig_id           :integer          not null
#  is_ok            :boolean          default(FALSE), not null
#  definition       :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  inspected_by_id  :integer
#
class RigInspection < ApplicationRecord
  belongs_to :form_template
  belongs_to :inspected_by, class_name: "DropzoneUser"
  belongs_to :dropzone_user
  belongs_to :rig

  scope :at_dropzone, -> (dropzone) { includes(:inspected_by).where(dropzone_users: { dropzone_id: dropzone.id}) }
  after_create :notify!
  after_save :notify!

  def notify!
    if (new_record? && is_ok?) || (is_ok? && !is_ok_was)
      Notification.create(
        received_by: dropzone_user,
        message: "Your equipment has been cleared to jump",
        type: :rig_inspection_completed,
        resource: self
      )
    end
  end

  def self.default_form
    [{
      label: "Monthly maintenance done?",
      valueType: "boolean",
      value: nil,
    }, {
      label: "Harness in good condition?",
      valueType: "boolean",
      value: nil,
    }, {
      label: "Cutaway and reserve handles secure?",
      valueType: "boolean",
      value: nil,
    }, {
      label: "3-ring routed correctly?",
      valueType: "boolean",
      value: nil,
    }, {
      label: "RSL/Skyhook connected and routed correctly?",
      valueType: "boolean",
      value: nil,
    }, {
      label: "Riser covers secure?",
      valueType: "boolean",
      value: nil,
    }, {
      label: "Reserve closing loop in good condition?",
      valueType: "boolean",
      value: nil,
    }, {
      label: "Reserve pilot chute seated and not exposed?",
      valueType: "boolean",
      value: nil,
    }, {
      label: "Main closing loop in good condition and correct length?",
      valueType: "boolean",
      value: nil,
    }, {
      label: "Main closing loop pin adequate tension?",
      valueType: "boolean",
      value: nil,
    }, {
      label: "Main tuck flaps in good condition and secure?",
      valueType: "boolean",
      value: nil,
    }, {
      label: "Pilot chute bridle secure and not exposed?",
      valueType: "boolean",
      value: nil,
    }, {
      label: "Pilot chute BOC in good condition?",
      valueType: "boolean",
      value: nil,
    }, {
      label: "Deployment type?",
      valueType: "string",
      value: "BOC"
    }, {
      label: "Cleared for freefly?",
      valueType: "boolean",
      value: nil
    }, {
      label: "Container general condition?",
      valueType: "string",
      value: nil
    }]
  end
end
