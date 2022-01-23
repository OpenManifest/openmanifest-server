# frozen_string_literal: true

class UserFederation < ApplicationRecord
  belongs_to :user
  belongs_to :federation
  belongs_to :license, optional: true
  has_many :dropzone_users, through: :user
  has_many :user_federation_qualifications
  has_many :qualifications, through: :user_federation_qualifications

  validates_uniqueness_of :user_id, scope: :federation_id

  after_save do
    next unless saved_change_to_license_id?
    dropzone_users.includes(:dropzone).where(
      dropzone: {
        federation_id: federation.id
      }
    ).update_all(license_id: license_id)
  end
end
