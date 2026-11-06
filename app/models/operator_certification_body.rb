# frozen_string_literal: true

# == Schema Information
#
# Table name: operator_certification_bodies
#
#  id                    :bigint           not null, primary key
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  certification_body_id :bigint           not null
#  operator_id           :bigint           not null
#
# The certification bodies an operator accepts
class OperatorCertificationBody < ApplicationRecord
  belongs_to :operator
  belongs_to :certification_body

  validates :certification_body_id, uniqueness: { scope: :operator_id }
end
