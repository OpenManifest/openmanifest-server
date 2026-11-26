# frozen_string_literal: true

# == Schema Information
#
# Table name: extras
#
#  id          :bigint           not null, primary key
#  name        :string
#  operator_id :bigint           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Extra < ApplicationRecord
  include MoneyAttributes

  money :cost
  include Discard::Model

  belongs_to :operator
  # The qualification a member must hold to add this extra (nitrox, for example)
  belongs_to :required_qualification, class_name: "Qualification", optional: true

  validate :qualification_of_accepted_body

  has_many :ticket_type_extras
  has_many :ticket_types, through: :ticket_type_extras

  private

  def qualification_of_accepted_body
    return if required_qualification.nil? || operator.certification_body_ids.include?(required_qualification.certification_body_id)

    errors.add(:required_qualification, :invalid)
  end
end
