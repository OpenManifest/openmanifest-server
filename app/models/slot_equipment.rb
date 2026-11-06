# frozen_string_literal: true

# == Schema Information
#
# Table name: slot_equipment
#
#  id           :bigint           not null, primary key
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  equipment_id :bigint           not null
#  slot_id      :bigint           not null
#
# An item a slot uses: a skydiver's rig, a diver's BCD, regulator and wetsuit
class SlotEquipment < ApplicationRecord
  self.table_name = "slot_equipment"

  belongs_to :slot
  belongs_to :equipment

  validates :equipment_id, uniqueness: { scope: :slot_id }
end
