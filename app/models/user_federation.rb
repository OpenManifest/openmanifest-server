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

  def sync_federation
    if federation.slug == "apf"
      sync_apf
    end
  end

  def sync_apf
    return unless user
    return unless uid
    *_, last_name = user.name.split(/\s+/)
    return unless last_name

    url = "https://www.apf.com.au/apf/api/student"
    params = {
      SurName: last_name,
      APFNum: uid
    }

    response = JSON.parse(
      HTTParty.get(
        [url, params.to_query].join("?")
      ).body
    )

    if response.count == 1
      user_info, = response

      # Find license that have not expired
      valid_licenses = user_info["Qualifications"].filter_map do |license_or_crest|
        if License.exists?(name: license_or_crest["Qualification"])
          License.find_by(name: license_or_crest["Qualification"])
        else
          user_federation_qualifications.find_or_create_by(
            qualification: Qualification.find_or_create_by(name: license_or_crest["Qualification"], federation: Federation.find_by(slug: :apf))
          )
          nil
        end
      end

      # Find the highest ranking license
      if license = License.find_by(id: valid_licenses.map(&:id).last)
        user.update(license: license)
        update(license: license)
      end
    end
  rescue => e
    puts e.message
    nil
  end
end
