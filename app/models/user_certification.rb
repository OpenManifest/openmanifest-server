# frozen_string_literal: true

# == Schema Information
#
# Table name: user_certifications
#
#  id                     :bigint           not null, primary key
#  number                 :string
#  uid                    :string
#  verified_at            :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  certification_body_id  :bigint           not null
#  certification_level_id :bigint
#  user_id                :bigint           not null
#  verified_by_id         :bigint
#
# What a user holds at a certification body: their member id (`uid`), the level they reached and the number of that
# certificate. A body without levels leaves the level empty and only holds qualifications.
class UserCertification < ApplicationRecord
  belongs_to :user
  belongs_to :certification_body
  belongs_to :certification_level, optional: true
  belongs_to :verified_by, class_name: "User", optional: true
  has_many :memberships, through: :user
  has_many :user_qualifications, dependent: :destroy
  has_many :qualifications, through: :user_qualifications

  validates_uniqueness_of :user_id, scope: :certification_body_id
  validate :level_of_the_body

  after_save :update_other_memberships_for_user

  def verified?
    verified_at.present?
  end

  private

  def level_of_the_body
    return if certification_level.blank? || certification_level.certification_body_id == certification_body_id

    errors.add(:certification_level, "does not belong to #{certification_body&.name}")
  end

  def update_other_memberships_for_user
    # Each membership takes the highest level the user holds at the bodies its operator accepts
    memberships.in_certification_body(certification_body_id).find_each(&:refresh_certification_level)
  end
end
