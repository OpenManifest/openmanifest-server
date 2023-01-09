# frozen_string_literal: true

class UserFederation < ApplicationRecord
  belongs_to :user
  belongs_to :federation
  belongs_to :license, optional: true
  has_many :dropzone_users, through: :user
  has_many :user_federation_qualifications
  has_many :qualifications, through: :user_federation_qualifications

  validates_uniqueness_of :user_id, scope: :federation_id

  after_save :update_other_dropzone_users_for_user

  private

  def update_other_dropzone_users_for_user
    # We have to do this because of
    # how postgres/rails handles nil values,
    # when doing a not-query nil values are ignored
    return unless dropzone_users.in_federation(federation_id).without_license(license_id).exists?

    dropzone_users.in_federation(federation_id).update_all(license_id: license_id)
  end
end
