# frozen_string_literal: true

# == Schema Information
#
# Table name: user_qualifications
#
#  id                    :bigint           not null, primary key
#  expires_at            :datetime
#  number                :string
#  verified_at           :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  qualification_id      :bigint           not null
#  user_certification_id :bigint           not null
#
# A qualification a user holds, with the number on it and an optional expiry. An expired one no longer counts.
class UserQualification < ApplicationRecord
  belongs_to :user_certification
  belongs_to :qualification
  has_one :user, through: :user_certification

  delegate :name, to: :qualification

  scope :current, -> { where(arel_table[:expires_at].eq(nil).or(arel_table[:expires_at].gt(Time.current))) }

  def current?
    expires_at.nil? || expires_at.future?
  end
end
