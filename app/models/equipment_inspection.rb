# frozen_string_literal: true

# == Schema Information
#
# Table name: equipment_inspections
#
#  id               :bigint           not null, primary key
#  definition       :text
#  is_ok            :boolean          default(FALSE), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  equipment_id     :bigint           not null
#  form_template_id :bigint           not null
#  inspected_by_id  :bigint
#  membership_id    :bigint           not null
#
# An inspection of an item by staff of an operator, made with the form of the item's kind. It stays valid for the
# kind's `inspection_valid_days` (a glider's daily inspection is valid for one day), forever without them.
class EquipmentInspection < ApplicationRecord
  belongs_to :form_template
  belongs_to :inspected_by, class_name: "Membership"
  belongs_to :membership
  belongs_to :equipment

  scope :ok, -> { where(is_ok: true) }
  scope :at_operator, ->(operator) { where(inspected_by_id: Membership.where(operator_id: operator.id).select(:id)) }
  # Inspections that are within the validity of their item's kind
  scope :current, -> {
    joins(equipment: :kind).where(
      "equipment_kinds.inspection_valid_days IS NULL OR " \
      "equipment_inspections.updated_at > CAST(:now AS timestamp) - (equipment_kinds.inspection_valid_days * INTERVAL '1 day')", now: Time.current
    )
  }

  after_save :notify!

  # Tells the owner when the equipment is cleared: when an inspection is created as ok, or becomes ok
  def notify!
    return unless is_ok? && saved_change_to_is_ok?

    Notification.create!(
      received_by: membership,
      message: "Your equipment has been cleared to jump",
      notification_type: :equipment_inspection_completed,
      resource: self
    )
  end

  def current?(now: Time.current)
    equipment.kind.inspection_valid?(updated_at, now: now)
  end
end
