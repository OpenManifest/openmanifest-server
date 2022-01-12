# frozen_string_literal: true

require "active_interaction"

class Federations::ApfSync < ActiveInteraction::Base
  include ActiveInteraction::Extras::Transaction
  run_in_transaction!
  record :user_federation

  def execute
    return if Rails.env.test?
    query_apf_api
    return nil if !@json || @json.count != 1
    extract_license
    assign_license
    extract_qualifications
    assign_qualifications
  end

  def query_apf_api
    @json = JSON.parse(
      URI.open(
        url
      ).read
    )
  rescue
    @json = nil
  end

  def extract_qualifications
    user_info, = @json

    # Find license that have not expired
    @qualifications = user_info["Qualifications"].filter_map do |license_or_crest|
      next if /Certificate/i.match?(license_or_crest["Qualification"])
      Qualification.find_or_create_by(
        name: license_or_crest["Qualification"],
        federation: user_federation.federation,
      )
    end
  end

  def assign_qualifications
    user_info, = @json

    @qualifications = user_info["Qualifications"].filter_map do |license_or_crest|
      next if /Certificate/i.match?(license_or_crest["Qualification"])

      UserFederationQualification.find_or_create_by({
        qualification: Qualification.find_by(
          name: license_or_crest["Qualification"],
          federation: user_federation.federation,
        ),
        user_federation_id: user_federation.id
      }.merge(
        uid: license_or_crest["SerialNumber"],
        expires_at: if license_or_crest["ExpiryDate"]
                      DateTime.parse(license_or_crest["ExpiryDate"])
                    else
                      nil
                    end
      ))
    end
  end

  def extract_license
    user_info, = @json

    # Find license that have not expired
    @licenses = user_info["Qualifications"].filter_map do |license_or_crest|
      { license_or_crest["Qualification"] => license_or_crest } if /Certificate/i.match?(license_or_crest["Qualification"])
    end.reduce(:merge)
  end

  def assign_license
    # Find the highest ranking license
    if license = License.where(name: @licenses.keys).order(id: :desc).first
      # Backwards compatibility:
      user_federation.user.update(license: license)

      user_federation.assign_attributes(
        license: license,
        license_number: @licenses[license.name]["SerialNumber"]
      )
      errors.merge!(user_federation.errors) unless user_federation.save
    end
  end


  private
    def api_url
      "https://www.apf.com.au/apf/api/student"
    end

    def last_name
      *_, last_name = user_federation.user.name.split(/\s+/)
      last_name
    end

    def query_params
      {
        SurName: last_name,
        APFNum: user_federation.uid
      }.to_query
    end

    def url
      [api_url, query_params].join("?")
    end
end
