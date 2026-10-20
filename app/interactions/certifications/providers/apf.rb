# frozen_string_literal: true

require "active_interaction"

# Verifies a member against the register of the Australian Parachute Federation (the `apf` verification provider): the
# highest certificate becomes the member's level, everything else (ratings, crests, licences) a qualification.
class Certifications::Providers::Apf < ApplicationInteraction
  record :user_certification

  steps :query_apf_api,
        :extract_certificates,
        :assign_certification_level,
        :extract_qualifications,
        :assign_qualifications,
        :save!

  success do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      level: :debug,
      resource: user_certification,
      action: :assigned,
      access_level: :admin,
      operator: access_context.operator,
      created_by: access_context.subject,
      message: "#{user_certification.user.name} successfully synced certification #{user_certification&.certification_level&.name} ##{user_certification.uid} with APF",
      details: "APF response: #{@json&.to_json}"
    )
  end

  error do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      level: :error,
      resource: user_certification,
      action: :assigned,
      access_level: :admin,
      operator: access_context.operator,
      created_by: access_context.subject,
      message: "#{user_certification.user.name} failed to sync certification #{user_certification&.certification_level&.name} ##{user_certification.uid} with APF",
      details: errors.full_messages.join(", ")
    )
  end

  def save!
    user_certification.save
    errors.merge!(user_certification.errors) if user_certification.errors.any?
    user_certification
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
        resource: user_certification,
        action: :assigned,
        access_level: :admin,
        operator: access_context.operator,
        created_by: access_context.subject,
        message: "#{user_certification.user.name} failed to sync certification #{user_certification&.certification_level&.name} ##{user_certification.uid} with APF: Failed to parse #{@json.count} (!= 1) results from APF API when querying #{url}",
        details: errors.full_messages.join(", ")
      )
    end
  rescue
    @json = nil
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      level: :error,
      resource: user_certification,
      action: :assigned,
      access_level: :admin,
      operator: access_context.operator,
      created_by: access_context.subject,
      message: "#{user_certification.user.name} failed to sync certification #{user_certification&.certification_level&.name} ##{user_certification.uid} with APF: Failed to parse response from APF API (#{url})",
      details: errors.full_messages.join(", ")
    )
  end

  def extract_qualifications
    user_info, = @json
    return unless user_info

    # Everything that is not a certificate is a qualification
    @qualifications = user_info["Qualifications"].filter_map do |entry|
      next if /Certificate/i.match?(entry["Qualification"])
      Qualification.find_or_create_by(
        name: entry["Qualification"],
        certification_body: user_certification.certification_body,
      )
    end
  rescue
    nil
  end

  def assign_qualifications
    user_info, = @json
    return unless user_info

    @qualifications = user_info["Qualifications"].filter_map do |entry|
      next if /Certificate/i.match?(entry["Qualification"])

      attrs = {
        qualification: Qualification.find_by(
          name: entry["Qualification"],
          certification_body: user_certification.certification_body,
        ),
        user_certification_id: user_certification.id,
      }.merge(
        number: entry["SerialNumber"],
        expires_at: if entry["ExpiryDate"]
                      DateTime.parse(entry["ExpiryDate"])
                    else
                      nil
                    end,
      )
      UserQualification.find_or_create_by(attrs)
    end
  rescue
    nil
  end

  def extract_certificates
    user_info, = @json
    return unless user_info

    @certificates = user_info["Qualifications"].filter_map do |entry|
      { entry["Qualification"] => entry } if /Certificate/i.match?(entry["Qualification"])
    end.reduce(:merge)
  rescue
    nil
  end

  def assign_certification_level
    return unless @certificates

    # Find the highest ranking certificate; the register answered, so the member is verified
    level = user_certification.certification_body.certification_levels.where(name: @certificates.keys).reorder(rank: :desc).first
    return unless level

    user_certification.assign_attributes(
      certification_level: level,
      number: @certificates.dig(level.name, "SerialNumber") || "",
      verified_at: Time.current
    )
    errors.merge!(user_certification.errors) unless user_certification.save
  end

  private

  def api_url
    "https://www.apf.com.au/apf/api/student"
  end

  def last_name
    *_, last_name = user_certification.user.name.split(/\s+/)
    last_name
  end

  def query_params
    {
      SurName: last_name,
      APFNum: user_certification.uid,
    }.to_query
  end

  def url
    [api_url, query_params].join("?")
  end
end
