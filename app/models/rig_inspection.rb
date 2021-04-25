# frozen_string_literal: true

# == Schema Information
#
# Table name: rig_inspections
#
#  id               :integer          not null, primary key
#  checklist_id     :integer          not null
#  inspected_by_id  :integer          not null
#  rig_id           :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  dropzone_user_id :integer          not null
#
class RigInspection < ApplicationRecord
  belongs_to :checklist
  belongs_to :inspected_by, class_name: "User"
  belongs_to :rig
  belongs_to :dropzone_user
  has_many :checklist_values
end
