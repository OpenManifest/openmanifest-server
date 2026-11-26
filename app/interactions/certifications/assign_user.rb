# frozen_string_literal: true

# Joins a user to a certification body at a level and, when the body has a verification provider, verifies the member
# with it. Qualifications come from the provider or are added by staff.
class Certifications::AssignUser < ApplicationInteraction
  record :certification_body
  record :certification_level, default: -> { certification_body.certification_levels.first }
  record :user
  string :uid, default: ''
  # The number on the certificate, when staff or the member enter it by hand
  string :number, default: nil
  validates :certification_body, :user, presence: true

  steps :assign_user_to_certification_body,
        :assign_user_certification_uid,
        :manually_assign_certification_level,
        :synchronize_qualifications,
        :save!

  success do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      resource: user,
      action: :assigned,
      access_level: :admin,
      operator: access_context.operator,
      created_by: access_context.subject,
      message: "#{user&.name || 'Unknown User'} joined #{certification_body&.name || 'Unknown certification body'} at level #{certification_level&.name} (#{uid.presence || 'No member number'})",
    )
  end

  error do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      resource: access_context.operator,
      action: :assigned,
      level: :error,
      access_level: :admin,
      operator: access_context.operator,
      created_by: access_context.subject,
      message: "#{user&.name || 'Unknown User'} failed to join #{certification_body&.name || 'Unknown certification body'} at level #{certification_level&.name} (#{uid.presence || 'No member number'})",
    )
  end

  def save!
    errors.merge!(@user_certification.errors) unless @user_certification.save
    @user_certification
  end

  def manually_assign_certification_level
    @user_certification.assign_attributes(
      certification_level: certification_level || certification_body.certification_levels.first,
      number: number.to_s
    )
    errors.merge!(@user_certification.errors) unless @user_certification.save
  end

  def assign_user_to_certification_body
    @user_certification ||= UserCertification.find_or_initialize_by(
      certification_body: certification_body,
      user: user
    )
  end

  def assign_user_certification_uid
    @user_certification.assign_attributes(
      uid: uid || ' '
    )
  end

  def synchronize_qualifications
    provider = certification_body.provider
    return unless provider

    compose(provider, user_certification: @user_certification, access_context: access_context)
  end
end
