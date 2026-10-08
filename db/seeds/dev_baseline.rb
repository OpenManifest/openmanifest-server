# frozen_string_literal: true

# Offline development dataset. Run: bin/rails db:seed db:seed:dev_baseline
# Login: owner@example.com / Password1!  (all users share the password)
raise "dev_baseline is for development/test only" if Rails.env.production?

Setup::Global::Seeds.run!

def dev_user(email, name, weight = 80)
  user = User.find_or_initialize_by(email: email)
  user.assign_attributes(name: name, phone: "0400000000", exit_weight: weight,
                         password: "Password1!", password_confirmation: "Password1!")
  user.skip_confirmation!
  user.save!
  user
end

owner = dev_user("owner@example.com", "Olive Owner")
dropzone = Dropzone.find_by(name: "Demo Dropzone")
dropzone ||= Setup::Dropzones::CreateDropzone.run!(
  name: "Demo Dropzone", owner: owner, federation: Federation.find_by(slug: "apf") || Federation.first,
  lat: nil, lng: nil, is_credit_system_enabled: true, primary_color: "#1D3557", secondary_color: "#E63946"
)
dropzone.update!(state: "public", settings: {
  require_membership: false, require_rig_inspection: false,
  require_reserve_in_date: false, require_equipment: false,
})

plane = dropzone.planes.find_or_create_by!(name: "Caravan", registration: "VH-ABC", min_slots: 2, max_slots: 14)
ticket = dropzone.ticket_types.find_or_create_by!(name: "Full altitude", cost: 40, altitude: 14_000,
                                                  allow_manifesting_self: true, currency: "AUD")
dropzone.ticket_types.find_or_create_by!(name: "Tandem", cost: 0, altitude: 14_000, allow_manifesting_self: false,
                                         is_tandem: true, currency: "AUD")
roles = dropzone.user_roles.index_by(&:name)
license = (Federation.find_by(slug: "apf") || Federation.first).licenses.where.not(name: "No license").first
members = {}
[
  ["pilot@example.com", "Pat Pilot", "pilot"], ["manifest@example.com", "Max Manifest", "manifest"],
  ["jumper1@example.com", "Jo Jumper", "fun_jumper"], ["jumper2@example.com", "Sam Skydiver", "fun_jumper"],
  ["student@example.com", "Stu Student", "student"],
].each do |email, name, role|
  membership = dropzone.dropzone_users.find_or_initialize_by(user: dev_user(email, name))
  membership.assign_attributes(user_role: roles.fetch(role), credits: 400, license: license, expires_at: 1.year.from_now)
  membership.save!
  members[email] = membership
end
owner_membership = dropzone.dropzone_users.find_by!(user: owner)
owner_membership.update!(credits: 1000, license: license, expires_at: 1.year.from_now)
%w(actAsPilot actAsGCA actAsLoadMaster actAsDZSO actAsRigInspector).each { |p| owner_membership.grant!(p) }
members["pilot@example.com"].grant!("actAsPilot")

if Load.joins(:plane).where(planes: { dropzone_id: dropzone.id }).none?
  context = ApplicationInteraction::AccessContext.new(owner_membership)
  first = Manifest::CreateLoad.run!(access_context: context, plane: plane, pilot: members["pilot@example.com"],
                                    gca: owner_membership, load_master: owner_membership, name: "Load 1")
  Manifest::CreateLoad.run!(access_context: context, plane: plane, pilot: members["pilot@example.com"],
                            gca: owner_membership, load_master: owner_membership, name: "Load 2")
  %w(jumper1@example.com jumper2@example.com).each do |email|
    Manifest::CreateSlot.run!(access_context: context, load: first, dropzone_user: members[email], ticket_type: ticket,
                              jump_type: JumpType.find_by(slug: "fs") || JumpType.first, exit_weight: 80)
  end
end
puts "dev_baseline: dropzone #{dropzone.id}, #{dropzone.loads.count} loads. Login owner@example.com / Password1!"
