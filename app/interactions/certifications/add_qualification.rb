# frozen_string_literal: true

# A user declares a qualification (a rating, a licence) with its number and optional expiry. It joins the user to the
# qualification's body without a level when they have not joined it yet. Staff verify it separately.
class Certifications::AddQualification < ApplicationInteraction
  record :user
  record :qualification
  string :number, default: nil
  date_time :expires_at, default: nil

  steps :save_user_qualification

  def save_user_qualification
    certification = UserCertification.find_or_initialize_by(user: user, certification_body: qualification.certification_body)
    certification.number ||= ""
    errors.merge!(certification.errors) unless certification.save

    held = certification.user_qualifications.find_or_initialize_by(qualification: qualification)
    held.assign_attributes(number: number, expires_at: expires_at)
    errors.merge!(held.errors) unless held.save
    held
  end
end
