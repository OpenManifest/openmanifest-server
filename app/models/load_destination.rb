# frozen_string_literal: true

# == Schema Information
#
# Table name: load_destinations
#
#  id             :bigint           not null, primary key
#  position       :integer          default(0), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  destination_id :bigint           not null
#  load_id        :bigint           not null
#
# A stop of a load with per-load destinations, in the order the load visits them.
class LoadDestination < ApplicationRecord
  belongs_to :load
  belongs_to :destination

  validates :position, numericality: { greater_than_or_equal_to: 0 }
  validate :same_operator

  private

  def same_operator
    return if load.nil? || destination.nil? || destination.operator_id == load.operator_id

    errors.add(:destination, :invalid)
  end
end
