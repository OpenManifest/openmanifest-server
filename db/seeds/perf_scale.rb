# frozen_string_literal: true

# Scales the dev_baseline operator for performance measurements (U6.3): 500 members and 6 loads of 14 seats on the
# operator's day. Run after dev_baseline: bin/rails db:seed:perf_scale. Reset with db:reset db:seed:dev_baseline, since the
# UI specs expect the baseline's few members and loads.
raise "perf_scale is for development/test only" if Rails.env.production?

operator = Operator.find_by!(name: "Demo Dropzone")
owner = operator.memberships.joins(:user).find_by!(users: { email: "owner@example.com" })
roles = operator.user_roles.index_by(&:name)
level = owner.certification_level
vehicle = operator.vehicles.find_by!(name: "Caravan")
ticket = operator.ticket_types.find_by!(name: "Full altitude")
activity = ActivityType.find_by(slug: "fs") || ActivityType.first
password = User.new(password: "Password1!").encrypted_password

members = 500
missing = members - operator.memberships.count
missing.times do |i|
  user = User.new(email: format("perf%03d@example.com", i), name: "Perf Member #{format('%03d', i)}",
                  phone: "0400000000", body_mass_kg: 80, encrypted_password: password)
  user.skip_confirmation!
  user.save!(validate: false)
  operator.memberships.create!(user: user, user_role: roles.fetch("fun_jumper"), credits: 400,
                               certification_level: level, expires_at: 1.year.from_now)
end

context = ApplicationInteraction::AccessContext.new(owner)
pilot = operator.memberships.joins(:user).find_by!(users: { email: "pilot@example.com" })
loads = Load.where(operator_id: operator.id).order(:id).to_a
(loads.size...6).each do |n|
  loads << Manifest::CreateLoad.run!(access_context: context, vehicle: vehicle, pilot: pilot, gca: owner,
                                     load_master: owner, name: "Load #{n + 1}")
end

busy = Slot.where(load: loads).pluck(:membership_id)
free = operator.memberships.joins(:user).where("users.email LIKE 'perf%'").where.not(id: busy).to_a
loads.first(6).each do |load|
  (14 - load.slots.count).times do
    outcome = Manifest::CreateSlot.run(access_context: context, load: load, membership: free.shift, ticket_type: ticket,
                                       activity_type: activity, body_mass_kg: 80)
    warn "perf_scale: #{outcome.errors.full_messages.to_sentence}" unless outcome.valid?
  end
end
puts "perf_scale: #{operator.memberships.count} members, " \
     "#{loads.first(6).map { |load| load.reload.slots.count }.join('/')} seats on 6 loads"
