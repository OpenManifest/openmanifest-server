# frozen_string_literal: true

# == Schema Information
#
# Table name: certification_levels
#
#  id                    :bigint           not null, primary key
#  equivalence_key       :string
#  name                  :string
#  rank                  :integer          default(0), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  certification_body_id :bigint           not null
#
# A level of a certification body. `rank` orders the levels within an industry across bodies (the numbers are comparable
# between bodies), `equivalence_key` names levels of different bodies that count as the same tier.
class CertificationLevel < ApplicationRecord
  belongs_to :certification_body, inverse_of: :certification_levels
  has_many :user_certifications, dependent: :restrict_with_error
  has_many :users, through: :user_certifications
  has_many :memberships, dependent: :restrict_with_error
  has_many :permitted_activities, dependent: :destroy
  has_many :activity_types, through: :permitted_activities

  scope :for_certification_body, ->(certification_body) { includes(:certification_body).where(certification_body: certification_body) }
  scope :at_least, ->(rank) { where(arel_table[:rank].gteq(rank)) }

  validates :name, presence: true, uniqueness: { scope: :certification_body_id }
  validates :rank, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Does this level count as the other, in any body? (same rank, or the same equivalence key)
  def equivalent_to?(other)
    other.present? && ((equivalence_key.present? && equivalence_key == other.equivalence_key) || rank == other.rank)
  end
end
