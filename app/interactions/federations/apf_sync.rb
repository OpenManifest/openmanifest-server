# frozen_string_literal: true

require "active_interaction"

class Federations::ApfSync < ApplicationInteraction
  record :user_federation

  steps :query_apf_api,
        :extract_license,
        :assign_license,
        :extract_qualifications,
        :assign_qualifications,
        :save!

  success do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      level: :debug,
      resource: user_federation,
      action: :assigned,
      access_level: :admin,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "#{user_federation.user.name} successfully synced license #{user_federation&.license&.name} ##{user_federation.uid} with APF",
      details: "APF response: #{@json&.to_json}"
    )
  end

  error do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      level: :error,
      resource: user_federation,
      action: :assigned,
      access_level: :admin,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "#{user_federation.user.name} failed to sync license #{user_federation&.license&.name} ##{user_federation.uid} with APF",
      details: errors.full_messages.join(", ")
    )
  end

  def save!
    user_federation.save
    errors.merge!(user_federation.errors) if user_federation.errors.any?
    user_federation
  end

  def query_apf_api
    @json = JSON.parse(
      HTTParty.get(
        url
      ).body
    )
    if @json.count != 1
      # Fail silently here in case this is composed from another interaction
      compose(
        ::Activity::CreateEvent,
        access_context: access_context,
        level: :error,
        resource: user_federation,
        action: :assigned,
        access_level: :admin,
        dropzone: access_context.dropzone,
        created_by: access_context.subject,
        message: "#{user_federation.user.name} failed to sync license #{user_federation&.license&.name} ##{user_federation.uid} with APF: Failed to parse #{@json.count} (!= 1) results from APF API when querying #{url}",
        details: errors.full_messages.join(", ")
      )
    end
  rescue
    @json = nil
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      level: :error,
      resource: user_federation,
      action: :assigned,
      access_level: :admin,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "#{user_federation.user.name} failed to sync license #{user_federation&.license&.name} ##{user_federation.uid} with APF: Failed to parse response from APF API (#{url})",
      details: errors.full_messages.join(", ")
    )
  end

  def extract_qualifications
    user_info, = @json
    return unless user_info

    # Find license that have not expired
    @qualifications = user_info["Qualifications"].filter_map do |license_or_crest|
      next if /Certificate/i.match?(license_or_crest["Qualification"])
      Qualification.find_or_create_by(
        name: license_or_crest["Qualification"],
        federation: user_federation.federation,
      )
    end
  rescue
    nil
  end

  def assign_qualifications
    user_info, = @json
    return unless user_info

    @qualifications = user_info["Qualifications"].filter_map do |license_or_crest|
      next if /Certificate/i.match?(license_or_crest["Qualification"])

      attrs = {
        qualification: Qualification.find_by(
          name: license_or_crest["Qualification"],
          federation: user_federation.federation,
        ),
        user_federation_id: user_federation.id,
      }.merge(
        uid: license_or_crest["SerialNumber"],
        expires_at: if license_or_crest["ExpiryDate"]
                      DateTime.parse(license_or_crest["ExpiryDate"])
                    else
                      nil
                    end,
      )
      UserFederationQualification.find_or_create_by(attrs)
    end
  rescue
    nil
  end

  def extract_license
    user_info, = @json
    return unless user_info

    # Find license that have not expired
    @licenses = user_info["Qualifications"].filter_map do |license_or_crest|
      { license_or_crest["Qualification"] => license_or_crest } if /Certificate/i.match?(license_or_crest["Qualification"])
    end.reduce(:merge)
  rescue
    nil
  end

  def assign_license
    return unless @licenses
    # Find the highest ranking license
    if license = user_federation.federation.licenses.where(name: @licenses.keys).order(id: :desc).first
      user_federation.assign_attributes(
        license: license,
        license_number: @licenses.dig(license.name, "SerialNumber") || ''
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
      APFNum: user_federation.uid,
    }.to_query
  end

  def url
    [api_url, query_params].join("?")
  end
end
