# frozen_string_literal: true

# Find demo operator
operator = Operator.find_by(name: "Demo")

# Create a 3 completed loads and 1 open load
(0..4).to_a.each do |index|
  random_vehicle = Vehicle.where(operator: operator).order(Arel.sql("RANDOM()")).first

  l = Load.create(
    name: "",
    vehicle: random_vehicle,
    max_slots: random_vehicle.capacity,
    is_open: index == 4,
    has_completed: true,
    dispatch_at: index == 4 ? nil : (3 - index).hours.ago,
    gca: Membership.where(operator: operator).order(Arel.sql("RANDOM()")).first.user,
  )

  dz_users = Membership.includes(:user).where.not(certification_level_id: nil).where(operator: operator).order(Arel.sql("RANDOM()")).take(random_vehicle.capacity + 1)
  filled_slots = index == 4 ? (random_vehicle.capacity / 3).to_i : random_vehicle.capacity

  puts "Load created"
  (0..filled_slots).each do |slot|
    puts "-- Creating slot #{slot}"
    Slot.create!(
      user: dz_users[slot].user,
      load: l,
      ticket_type: operator.ticket_types.where(allow_manifesting_self: true).order(Arel.sql("RANDOM()")).first,
      body_mass_kg: dz_users[slot].user.body_mass_kg,
      equipment_id: dz_users[slot].user.equipment.first,
      activity_type: dz_users[slot].user.activity_types.order(Arel.sql("RANDOM()")).first,
    )
  end
end

# Create 1 open load

# Manifest users on load
