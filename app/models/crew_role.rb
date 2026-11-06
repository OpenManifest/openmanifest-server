# frozen_string_literal: true

# == Schema Information
#
# Table name: crew_roles
#
#  id            :bigint           not null, primary key
#  discarded_at  :datetime
#  key           :string           not null
#  name          :string           not null
#  occupies_slot :boolean          default(FALSE), not null
#  permission    :string
#  position      :integer          default(0), not null
#  required      :boolean          default(FALSE), not null
#  scope         :string           default("load"), not null
#  vehicle_kinds :jsonb            not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  operator_id   :bigint           not null
#
# A job on a load (GENERALISATION §7): pilot, GCA, skipper, guide, ranger. An operator defines its own. A `load` role is
# filled once per load; a `vehicle` role once per vehicle of the load that it applies to (the ones that carry, or the
# kinds in `vehicle_kinds`). `permission` is what a member needs to fill it; crew with `occupies_slot` take a seat.
class CrewRole < ApplicationRecord
  include Discard::Model

  SCOPES = %w(load vehicle).freeze

  belongs_to :operator
  has_many :load_crew_assignments, dependent: :destroy

  validates :key, presence: true, format: { with: /\A[a-z][a-z0-9_]*\z/ }, uniqueness: { scope: :operator_id, conditions: -> { kept } }
  validates :name, presence: true
  validates :scope, inclusion: { in: SCOPES }
  validate :permission_known

  scope :ordered, -> { order(:position, :id) }

  # Adds the crew roles of the operator's industry template that it does not have (once; the operator owns them afterwards)
  def self.create_presets!(operator)
    operator.industry_template.presets.fetch("crew_roles", []).each_with_index do |attrs, position|
      next if operator.crew_roles.kept.exists?(key: attrs.fetch("key"))

      operator.crew_roles.create!(attrs.slice("key", "name", "scope", "required", "occupies_slot", "permission", "vehicle_kinds").merge(position: position))
    end
  end

  def load_scope? = scope == "load"

  def vehicle_scope? = scope == "vehicle"

  # Does a role of vehicle scope apply to this vehicle of a load? (the kinds named on the role, else any that carries)
  def applies_to?(load_vehicle)
    return false if load_vehicle.nil? || !load_vehicle.carrying?

    vehicle_kinds.blank? || vehicle_kinds.include?(load_vehicle.vehicle.kind)
  end

  # May this member fill the role? Roles without a permission can be filled by any member of the operator
  def fillable_by?(membership)
    membership.operator_id == operator_id && (permission.blank? || membership.can?(permission))
  end

  private

  def permission_known
    return if permission.blank? || ::Permission.exists?(name: permission)

    errors.add(:permission, :inclusion)
  end
end
