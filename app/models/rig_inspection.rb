# frozen_string_literal: true

# == Schema Information
#
# Table name: rig_inspections
#
#  id               :bigint           not null, primary key
#  form_template_id :bigint           not null
#  membership_id :bigint           not null
#  rig_id           :bigint           not null
#  is_ok            :boolean          default(FALSE), not null
#  definition       :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  inspected_by_id  :bigint
#
class RigInspection < ApplicationRecord
  belongs_to :form_template
  belongs_to :inspected_by, class_name: "Membership"
  belongs_to :membership
  belongs_to :rig

  scope :at_operator, -> (operator) { includes(:inspected_by).where(memberships: { operator_id: operator.id }) }
  after_save :notify!

  # Tells the owner when the rig is cleared to jump: when an inspection is created as ok, or becomes ok
  def notify!
    return unless is_ok? && saved_change_to_is_ok?

    Notification.create!(
      received_by: membership,
      message: "Your equipment has been cleared to jump",
      notification_type: :rig_inspection_completed,
      resource: self
    )
  end
end
