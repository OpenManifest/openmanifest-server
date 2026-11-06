# frozen_string_literal: true

# == Schema Information
#
# Table name: load_crew_assignments
#
#  id              :bigint           not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  crew_role_id    :bigint           not null
#  load_id         :bigint           not null
#  load_vehicle_id :bigint
#  membership_id   :bigint           not null
#
# Who fills a crew role on a load: for the whole load, or for one vehicle of it (a guide per raft).
class LoadCrewAssignment < ApplicationRecord
  belongs_to :load, inverse_of: :crew_assignments
  belongs_to :load_vehicle, optional: true
  belongs_to :crew_role
  belongs_to :membership

  validate :scope_matches, :same_operator

  private

  # A load role has no vehicle, a vehicle role has one the role applies to (on this load)
  def scope_matches
    return if crew_role.nil?

    if crew_role.load_scope?
      errors.add(:load_vehicle, :present) if load_vehicle
    elsif load_vehicle.nil? || !crew_role.applies_to?(load_vehicle) || (load_vehicle.load_id && load_vehicle.load_id != load_id)
      errors.add(:load_vehicle, :invalid)
    end
  end

  def same_operator
    return if crew_role.nil? || membership.nil? || load.nil? || load.operator_id.nil?

    errors.add(:membership, :invalid) unless crew_role.operator_id == load.operator_id && membership.operator_id == load.operator_id
  end
end
