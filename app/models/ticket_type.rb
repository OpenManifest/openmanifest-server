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

  validate :default_destination_of_operator

  private

  def default_destination_of_operator
    return if default_destination.nil? || default_destination.operator_id == operator_id

    errors.add(:default_destination, :invalid)
  end
end
