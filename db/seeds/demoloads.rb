# Find demo dropzone
dropzone = Dropzone.find_by(name: "Demo")

# Create a 3 landed loads and 1 open load
(0..4).to_a.each do |index|
  random_plane = Plane.where(dropzone: dropzone).order(Arel.sql('RANDOM()')).first

  l = Load.create(
    name: "",
    plane: random_plane,
    max_slots: random_plane.max_slots,
    is_open: index == 4,
    has_landed: true,
    dispatch_at: index == 4 ? nil : (3 - index).hours.ago,
    gca: DropzoneUser.where(dropzone: dropzone).order(Arel.sql("RANDOM()")).first.user,
  )

  dz_users = DropzoneUser.includes(:user).where.not(user: { license_id: nil }).where(dropzone: dropzone).order(Arel.sql("RANDOM()")).take(random_plane.max_slots + 1)
  filled_slots = index == 4 ? (random_plane.max_slots / 3).to_i : random_plane.max_slots

  puts "Load created"
  (0..filled_slots).each do |slot|
    puts "-- Creating slot #{slot}"
    Slot.create!(
      user: dz_users[slot].user,
      load: l,
      ticket_type: dropzone.ticket_types.where(allow_manifesting_self: true).order(Arel.sql("RANDOM()")).first,
      exit_weight: dz_users[slot].user.exit_weight,
      rig_id: dz_users[slot].user.rigs.first,
      jump_type: dz_users[slot].user.jump_types.order(Arel.sql("RANDOM()")).first,
    )
  end
end

# Create 1 open load

# Manifest users on load