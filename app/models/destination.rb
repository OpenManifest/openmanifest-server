# frozen_string_literal: true

# == Schema Information
#
# Table name: destinations
#
#  id                     :bigint           not null, primary key
#  discarded_at           :datetime
#  kind                   :string           default("altitude"), not null
#  location               :jsonb            not null
#  min_certification_rank :integer
#  name                   :string           not null
#  stops                  :jsonb            not null
#  altitude_m             :decimal(10, 2)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  operator_id            :bigint           not null
#
# Where a load goes (GENERALISATION §4): an exit altitude, a dive site, a route or a river section. What an operator can
# create is limited by the destinations module of its template (`kinds`), and where it is used by the module's `scope`:
# per slot (skydiving: every jumper has an altitude) or per load (the boat visits site 1, then site 2).
class Destination < ApplicationRecord
  include Discard::Model

  KINDS = %w(altitude site route section).freeze
  FEET = 0.3048

  # The usual skydiving altitudes by name, in feet
  NAMED_ALTITUDES = { 4000 => "Hop n Pop", 14_000 => "Full altitude" }.freeze

  belongs_to :operator
  has_many :load_destinations, dependent: :destroy
  has_many :loads, through: :load_destinations
  has_many :slots, dependent: :nullify
  has_many :ticket_types, foreign_key: :default_destination_id, inverse_of: :default_destination, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :operator_id, conditions: -> { kept } }
  validates :kind, inclusion: { in: KINDS }
  validates :altitude_m, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :altitude_m, presence: true, if: -> { kind == "altitude" }
  validate :kind_allowed

  # An archived destination is no longer offered: ticket types stop defaulting to it, past slots and loads keep it
  after_discard { ticket_types.update_all(default_destination_id: nil) }

  # The altitude destination of an operator at this height (feet), created when it has none
  def self.altitude_for(operator, feet)
    metres = (feet * FEET).round(2)
    operator.destinations.find_by(kind: "altitude", altitude_m: metres) ||
      operator.destinations.create!(kind: "altitude", altitude_m: metres, name: NAMED_ALTITUDES.fetch(feet) { "#{feet} ft" })
  end

  # The height in whole feet, for the displays and the daily log that still count in feet (units arrive with P7.12)
  def altitude_ft
    (altitude_m / FEET).round if altitude_m
  end

  def altitude_ft=(feet)
    self.altitude_m = feet.nil? ? nil : (feet * FEET).round(2)
  end

  private

  def kind_allowed
    return if operator.nil? || kind.blank?

    allowed = operator.module_config(:destinations)&.fetch("kinds", nil)
    errors.add(:kind, :inclusion) if allowed.blank? || allowed.exclude?(kind)
  end
end
