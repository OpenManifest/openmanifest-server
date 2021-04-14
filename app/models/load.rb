# == Schema Information
#
# Table name: loads
#
#  id             :integer          not null, primary key
#  dispatch_at    :datetime
#  has_landed     :boolean
#  plane_id       :integer          not null
#  load_master_id :integer
#  gca_id         :integer
#  pilot_id       :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class Load < ApplicationRecord
  belongs_to :plane
  belongs_to :load_master, class_name: "User"
  belongs_to :gca, class_name: "User"

  has_many :slots

  def ready?
    gca.present? && load_master.present? && plane.present? && slots.select(&:ready?).count >= plane.min_slots
  end
end
