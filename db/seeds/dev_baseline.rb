# frozen_string_literal: true

# Offline development dataset. Run: bin/rails db:seed db:seed:dev_baseline
# Login: owner@example.com / Password1!  (all users share the password)
raise "dev_baseline is for development/test only" if Rails.env.production?

Setup::Global::Seeds.run!

def dev_user(email, name, weight = 80)
  user = User.find_or_initialize_by(email: email)
  user.assign_attributes(name: name, phone: "0400000000", body_mass_kg: weight,
                         password: "Password1!", password_confirmation: "Password1!")
  user.skip_confirmation!
  user.save!
  user
end

owner = dev_user("owner@example.com", "Olive Owner")
operator = Operator.find_by(name: "Demo Dropzone")
operator ||= Setup::Operators::CreateOperator.run!(
  name: "Demo Dropzone", industry: "skydiving", time_zone: "Australia/Brisbane", owner: owner,
  certification_body_ids: [(CertificationBody.find_by(slug: "apf") || CertificationBody.first).id],
  lat: nil, lng: nil, is_credit_system_enabled: true, primary_color: "#1D3557", secondary_color: "#E63946"
)
operator.update!(state: "public", settings: {
  require_membership: false, require_equipment_inspection: false,
  require_equipment_in_service: false, require_equipment: false,
})

vehicle = operator.vehicles.find_or_create_by!(name: "Caravan", registration: "VH-ABC", min_capacity: 2, capacity: 14)
ticket = operator.ticket_types.find_or_create_by!(name: "Full altitude", cost_cents: 4000,
                                                  default_destination: Destination.altitude_for(operator, 14_000),
                                                  allow_manifesting_self: true, currency: "AUD")
operator.ticket_types.find_or_create_by!(name: "Tandem", cost_cents: 0, default_destination: Destination.altitude_for(operator, 14_000),
                                         allow_manifesting_self: false, requires_escort: true, currency: "AUD")
roles = operator.user_roles.index_by(&:name)
apf = CertificationBody.find_by(slug: "apf") || CertificationBody.first
level = apf.certification_levels.where.not(name: "No license").first
members = {}
[
  ["pilot@example.com", "Pat Pilot", "pilot"], ["manifest@example.com", "Max Manifest", "manifest"],
  ["jumper1@example.com", "Jo Jumper", "fun_jumper"], ["jumper2@example.com", "Sam Skydiver", "fun_jumper"],
  ["student@example.com", "Stu Student", "student"],
].each do |email, name, role|
  membership = operator.memberships.find_or_initialize_by(user: dev_user(email, name))
  membership.assign_attributes(user_role: roles.fetch(role), credits: 400, certification_level: level, expires_at: 1.year.from_now)
  membership.save!
  UserCertification.find_or_create_by!(user: membership.user, certification_body: apf) { |held| held.certification_level = level }
  members[email] = membership
end
owner_membership = operator.memberships.find_by!(user: owner)
owner_membership.update!(credits: 1000, certification_level: level, expires_at: 1.year.from_now)
UserCertification.find_or_create_by!(user: owner, certification_body: apf) { |held| held.certification_level = level }
%w(actAsPilot actAsGCA actAsLoadMaster actAsDutyOfficer actAsEquipmentInspector).each { |p| owner_membership.grant!(p) }
members["pilot@example.com"].grant!("actAsPilot")

if Load.where(operator_id: operator.id).none?
  context = ApplicationInteraction::AccessContext.new(owner_membership)
  first = Manifest::CreateLoad.run!(access_context: context, vehicle: vehicle, pilot: members["pilot@example.com"],
                                    gca: owner_membership, load_master: owner_membership, name: "Load 1")
  Manifest::CreateLoad.run!(access_context: context, vehicle: vehicle, pilot: members["pilot@example.com"],
                            gca: owner_membership, load_master: owner_membership, name: "Load 2")
  %w(jumper1@example.com jumper2@example.com).each do |email|
    Manifest::CreateSlot.run!(access_context: context, load: first, membership: members[email], ticket_type: ticket,
                              activity_type: ActivityType.find_by(slug: "fs") || ActivityType.first, body_mass_kg: 80)
  end
end
puts "dev_baseline: operator #{operator.id}, #{operator.loads.count} loads. Login owner@example.com / Password1!"
