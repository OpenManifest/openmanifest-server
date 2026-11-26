# frozen_string_literal: true

# Fills an operator with the demo data of its industry template (`config/industries/<slug>/demo.yml`): vehicles, staff and
# participants with their roles, certifications, qualifications and dates of birth, and guests. The destinations, ticket
# types and crew roles come from the template's presets already. People get example.com addresses: `email_prefix`
# makes them predictable (the dev seed's `scuba-sandy.skipper@example.com`), else they are unique. Safe to run again.
class Demo::Generators::TemplateOperator < ApplicationInteraction
  record :operator
  string :email_prefix, default: nil
  string :password, default: -> { SecureRandom.base58(16) }

  steps :create_vehicles,
        :create_people,
        :create_guests

  def create_vehicles
    demo.fetch("vehicles", []).each do |attrs|
      operator.vehicles.find_or_create_by!(name: attrs.fetch("name")) do |vehicle|
        vehicle.assign_attributes(attrs.slice("registration", "capacity", "kind", "max_payload_kg"))
        vehicle.min_capacity = 1
      end
    end
  end

  def create_people
    demo.fetch("people", []).each do |attrs|
      user = person(attrs)
      membership = operator.memberships.find_or_initialize_by(user: user)
      membership.user_role = operator.user_roles.find_by!(name: attrs.fetch("role"))
      membership.save!
      certify(user, attrs) if attrs["certification"]
      membership.refresh_certification_level
    end
  end

  def create_guests
    demo.fetch("guests", []).each do |attrs|
      ::Guest.find_or_create_by!(operator: operator, name: attrs.fetch("name")) do |guest|
        guest.assign_attributes(attrs.slice("date_of_birth", "body_mass_kg"))
      end
    end
  end

  private

  def demo = operator.industry_template.demo

  def person(attrs)
    name = attrs.fetch("name")
    email = email_prefix ? "#{email_prefix}#{name.parameterize(separator: '.')}@example.com" : "demo+#{SecureRandom.hex(6)}@example.com"
    user = ::User.find_or_initialize_by(email: email)
    user.assign_attributes(name: name, phone: "0400000000", body_mass_kg: attrs.fetch("body_mass_kg", 75), date_of_birth: attrs["date_of_birth"])
    if user.new_record?
      user.password = user.password_confirmation = password
      user.skip_confirmation!
    end
    user.save!
    user
  end

  # A level of the given rank at the body, and the body's qualifications of the given slugs
  def certify(user, attrs)
    body = ::CertificationBody.find_by!(slug: attrs.dig("certification", "body"))
    level = body.certification_levels.find_by!(rank: attrs.dig("certification", "rank"))
    held = ::UserCertification.find_or_initialize_by(user: user, certification_body: body)
    held.update!(certification_level: level)
    Array(attrs["qualifications"]).each do |slug|
      held.user_qualifications.find_or_create_by!(qualification: body.qualifications.find_by!(slug: slug))
    end
  end
end
