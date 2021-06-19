# frozen_string_literal: true

# == Schema Information
#
# Table name: planes
#
#  id                     :integer          not null, primary key
#  name                   :string
#  min_slots              :integer
#  max_slots              :integer
#  hours                  :integer
#  next_maintenance_hours :integer
#  registration           :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  dropzone_id            :integer          not null
#  is_deleted             :boolean          default(FALSE)
#
class Plane < ApplicationRecord
  has_many :loads, dependent: :destroy
  has_many :pilots, through: :loads
  belongs_to :dropzone
end
