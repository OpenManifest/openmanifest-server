# frozen_string_literal: true

# == Schema Information
#
# Table name: load_vehicles
#
#  id          :bigint           not null, primary key
#  position    :integer          default(0), not null
#  role        :string           default("carrying"), not null
#  slots_count :integer          default(0), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  load_id     :bigint           not null
#  vehicle_id  :bigint           not null
#
# A vehicle of a load (GENERALISATION §7): it carries participants (and has seats of its own) or supports the load (a
# tug, a chase vehicle, a shuttle). `slots_count` counts the slots assigned to this vehicle.
class LoadVehicle < ApplicationRecord
  ROLES = %w(carrying support).freeze

  belongs_to :load, inverse_of: :load_vehicles
  belongs_to :vehicle
  has_many :slots, dependent: :nullify
  has_many :crew_assignments, class_name: "LoadCrewAssignment", dependent: :destroy

  validates :role, inclusion: { in: ROLES }
  validates :vehicle_id, uniqueness: { scope: :load_id }, on: :update
  validate :same_operator

  scope :carrying, -> { where(role: "carrying") }

  def carrying? = role == "carrying"

  def support? = role == "support"

  # The seats of the vehicle; a support vehicle has none for participants
  def capacity = carrying? ? vehicle.capacity.to_i : 0

  def available_slots = capacity - slots_count

  private

  def same_operator
    return if load.nil? || vehicle.nil? || load.operator_id.nil? || vehicle.operator_id == load.operator_id

    errors.add(:vehicle, :invalid)
  end
end
