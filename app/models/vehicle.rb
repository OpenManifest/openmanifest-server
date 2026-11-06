# frozen_string_literal: true

# == Schema Information
#
# Table name: vehicles
#
#  id                     :bigint           not null, primary key
#  name                   :string
#  capacity               :integer
#  min_capacity           :integer
#  kind                   :string           not null
#  hours                  :integer
#  next_maintenance_hours :integer
#  registration           :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  operator_id            :bigint           not null
#  max_payload_kg         :decimal(8, 2)
#
class Vehicle < ApplicationRecord
  include Discard::Model
  include DailyLogEntry::Vehicle

  has_many :load_vehicles, dependent: :destroy
  has_many :loads, through: :load_vehicles
  has_many :pilots, through: :loads
  belongs_to :operator

  before_validation { self.kind ||= operator&.vehicle_kinds&.first }
  validates :kind, presence: true
end
