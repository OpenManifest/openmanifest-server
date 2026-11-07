# frozen_string_literal: true

# == Schema Information
#
# Table name: ticket_types
#
#  id                     :bigint           not null, primary key
#  currency               :string
#  name                   :string
#  operator_id            :bigint           not null
#  default_destination_id :bigint
#  allow_manifesting_self :boolean
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  participant_limits     :jsonb            not null
#  group_limits           :jsonb            not null
#  requires_escort        :boolean          default(FALSE)
#  escort_capacity        :integer          default(1), not null
#  escort_qualification_id :bigint
#  escort_crew_role_id    :bigint
#  min_certification_rank :integer
#  required_qualification_id :bigint
#
class TicketType < ApplicationRecord
  include MoneyAttributes

  money :cost
  include Discard::Model

  belongs_to :operator
  has_many :ticket_type_extras, dependent: :destroy
  has_many :extras, through: :ticket_type_extras
  has_many :slots
  belongs_to :default_destination, class_name: "Destination", optional: true, inverse_of: :ticket_types

  # What the member must hold to buy this ticket: a level of at least this rank (at any body the operator accepts), and a
  # current qualification
  belongs_to :required_qualification, class_name: "Qualification", optional: true

  # Escorts (GENERALISATION §10; skydiving: tandem): a slot of a ticket type that requires an escort takes up to
  # `escort_capacity` guests, who ride with the slot's member, the escort. The escort may need a qualification and the
  # permission of a crew role (a tandem instructor's rating, the right to act as a guide).
  belongs_to :escort_qualification, class_name: "Qualification", optional: true
  belongs_to :escort_crew_role, class_name: "CrewRole", optional: true

  validates :escort_capacity, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :min_certification_rank, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validate :limits_are_numbers
  validate :default_destination_of_operator, :qualification_of_accepted_body, :escort_requirements_of_operator

  # @return [Array<Symbol>] what the member lacks of the certification requirements: `:certification_rank`, `:qualification`
  def unmet_certification_requirements(membership)
    unmet = []
    unmet << :certification_rank if min_certification_rank && membership.certification_rank < min_certification_rank
    unmet << :qualification unless membership.user.qualified_for?(required_qualification)
    unmet
  end

  # @return [Array<Symbol>] what the escort lacks: `:qualification`, `:crew_role`
  def unmet_escort_requirements(membership)
    unmet = []
    unmet << :qualification unless membership.user.qualified_for?(escort_qualification)
    unmet << :crew_role if escort_crew_role && !escort_crew_role.fillable_by?(membership)
    unmet
  end

  PARTICIPANT_LIMITS = %w(min_age max_age min_body_mass_kg max_body_mass_kg).freeze
  GROUP_LIMITS = %w(max_group_body_mass_kg max_group_size).freeze

  private

  # Only the known limits, each a number of zero or more; a minimum is not above its maximum
  def limits_are_numbers
    { participant_limits: PARTICIPANT_LIMITS, group_limits: GROUP_LIMITS }.each do |attribute, known|
      limits = public_send(attribute)
      next errors.add(attribute, :invalid) unless limits.is_a?(Hash)

      limits.each do |key, value|
        errors.add(attribute, "#{key} is not a limit") unless known.include?(key)
        errors.add(attribute, "#{key} must be a number of zero or more") unless value.nil? || (value.is_a?(Numeric) && value >= 0)
      end
    end
    %w(age body_mass_kg).each do |name|
      min = participant_limits["min_#{name}"]
      max = participant_limits["max_#{name}"]
      errors.add(:participant_limits, "min_#{name} is above max_#{name}") if min && max && min.is_a?(Numeric) && max.is_a?(Numeric) && min > max
    end
  end

  def escort_requirements_of_operator
    errors.add(:escort_crew_role, :invalid) if escort_crew_role && escort_crew_role.operator_id != operator_id
    return if escort_qualification.nil? || operator.certification_body_ids.include?(escort_qualification.certification_body_id)

    errors.add(:escort_qualification, :invalid)
  end

  def qualification_of_accepted_body
    return if required_qualification.nil? || operator.certification_body_ids.include?(required_qualification.certification_body_id)

    errors.add(:required_qualification, :invalid)
  end

  def default_destination_of_operator
    return if default_destination.nil? || default_destination.operator_id == operator_id

    errors.add(:default_destination, :invalid)
  end
end
