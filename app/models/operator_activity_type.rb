# frozen_string_literal: true

# == Schema Information
#
# Table name: operator_activity_types
#
#  id               :bigint           not null, primary key
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  activity_type_id :bigint           not null
#  operator_id      :bigint           not null
#
# An activity type an operator offers (seeded from the template's presets, edited by the operator)
class OperatorActivityType < ApplicationRecord
  belongs_to :operator
  belongs_to :activity_type

  validates :activity_type_id, uniqueness: { scope: :operator_id }
end
