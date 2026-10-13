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
#  is_tandem              :boolean          default(FALSE)
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

  validates :min_certification_rank, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validate :default_destination_of_operator, :qualification_of_accepted_body

  # @return [Array<Symbol>] what the member lacks of the certification requirements: `:certification_rank`, `:qualification`
  def unmet_certification_requirements(membership)
    unmet = []
    unmet << :certification_rank if min_certification_rank && membership.certification_rank < min_certification_rank
    unmet << :qualification unless membership.user.qualified_for?(required_qualification)
    unmet
  end

  private

  def qualification_of_accepted_body
    return if required_qualification.nil? || operator.certification_body_ids.include?(required_qualification.certification_body_id)

    errors.add(:required_qualification, :invalid)
  end

  def default_destination_of_operator
    return if default_destination.nil? || default_destination.operator_id == operator_id

    errors.add(:default_destination, :invalid)
  end
end
