# frozen_string_literal: true

require "open-uri"

# Create an operator with this user
operator = Operator.find_or_initialize_by(
  name: "Demo",
)

if operator.new_record?
  # Create a fake user
  owner = User.create_fake
  operator.federation = Federation.first
  operator.is_public = true
  operator.primary_color = "#1D3557"
  operator.secondary_color = "#E63946"
  operator.is_credit_system_enabled = true

  operator.image = "data:image/jpg;base64,#{Base64.encode64(open('https://picsum.photos/800/600').read)}"
  operator.save!

  ## Make current user owner
  Membership.create(
    operator: operator,
    user: owner,
    user_role: UserRole.find_by(
      operator_id: operator.id,
      name: "owner"
    )
  )

  operator.rig_inspection_template = FormTemplate.create(
    name: "Rig Inspection",
    definition: RigInspection.default_form.to_json,
    created_by: owner,
    updated_by: owner,
  )
  operator.save!
  operator.rig_inspection_template.update(operator: operator)

  puts "-- Creating planes"
  # Create a plane
  Plane.create(
    operator: operator,
    name: "C182",
    min_slots: 2,
    max_slots: 4,
    registration: "DKL-493",
  )

  # Create a plane
  Plane.create(
    operator: operator,
    name: "Caravan",
    min_slots: 10,
    max_slots: 16,
    registration: "DKZ-203",
  )

  puts "--Creating ticket type: Height"
  # Create default ticket types
  height = TicketType.create(
    operator: operator,
    cost: 45,
    name: "Height",
    altitude: 14000,
    allow_manifesting_self: true,
    is_tandem: false,
    currency: "AUD"
  )

  puts "--Creating ticket type: Hop n Pop"
  TicketType.create(
    operator: operator,
    cost: 25,
    name: "Hop n Pop",
    altitude: 4500,
    allow_manifesting_self: true,
    is_tandem: true,
    currency: "AUD"
  )

  puts "--Creating ticket type: Tandem"
  tandem = TicketType.create(
    operator: operator,
    cost: 199,
    name: "Tandem",
    altitude: 14000,
    allow_manifesting_self: false,
    is_tandem: true,
    currency: "AUD"
  )

  # Create default ticket addons
  puts "--Creating ticket addon: Outside camera"
  outside_cam = Extra.create(
    operator: operator,
    cost: 100,
    name: "Outside camera"
  )

  # Create default ticket addons
  puts "--Creating ticket addon: Handycam"
  handy_cam = Extra.create(
    operator: operator,
    cost: 50,
    name: "Handycam"
  )

  # Create default ticket addons
  puts "--Creating ticket addon: Coach"
  coach = Extra.create(
    operator: operator,
    cost: 90,
    name: "Coach"
  )

  TicketTypeExtra.create(
    ticket_type: height,
    extra: coach
  )

  TicketTypeExtra.create(
    ticket_type: tandem,
    extra: handy_cam
  )

  TicketTypeExtra.create(
    ticket_type: tandem,
    extra: outside_cam
  )
end

if operator.memberships.length < 2
  # Create 5 instructors
  instructors = (1..5).to_a.map do |index|
    # Create default ticket addons
    role = index == 1 ? "chief_instructor" : "aff_instructor"
    u = User.create_fake

    puts "-- User [#{role}]: #{u.name}"
    Membership.create(
      user: u,
      operator: operator,
      user_role: UserRole.find_by(
        operator: operator,
        name: role
      )
    )
  end

  # Create 4 pilots
  (1..4).to_a.each do |index|
    u = User.create_fake

    puts "-- User [pilot]: #{u.name}"
    Membership.create(
      user: u,
      operator: operator,
      user_role: UserRole.find_by(
        operator: operator,
        name: "pilot"
      )
    )
  end

  # Create 30 jumpers
  (1..30).to_a.each do |index|
    dz_user = Membership.create(
      user: User.create_fake,
      operator: operator,
      user_role: UserRole.find_by(
        operator: operator,
        name: "fun_jumper"
      )
    )

    # Pick a random license
    dz_user.user.update(
      license: License.order(Arel.sql("RANDOM()")).first
    )

    puts "-- Created user [#{dz_user.user_role.name}]: #{dz_user.user.name} (License #{dz_user.user.license.name})"

    # Create a rig
    case index % 3
    when 0
      Rig.create(
        make: "Mirage",
        model: "G4.1",
        serial: ((Random.rand * 20000) + 10000).to_i.to_s,
        pack_value: 10,
        canopy_size: [120, 150, 170, 190].sample,
        repack_expires_at: DateTime.now + ((Random.rand * 360) + 90).days,
        user: dz_user.user,
      )
    when 1
      Rig.create(
        make: "Vector",
        model: "V310",
        serial: ((Random.rand * 20000) + 10000).to_i.to_s,
        pack_value: 10,
        canopy_size: [120, 150, 170, 190].sample,
        repack_expires_at: DateTime.now + ((Random.rand * 360) + 90).days,
        user: dz_user.user,
      )
    when 2
      Rig.create(
        make: "Javelin",
        model: "J3FK",
        serial: ((Random.rand * 20000) + 10000).to_i.to_s,
        pack_value: 10,
        canopy_size: [120, 150, 170, 190].sample,
        repack_expires_at: DateTime.now + ((Random.rand * 360) + 90).days,
        user: dz_user.user,
      )
    end

    puts "-- Creating rig inspection for #{dz_user.user.name}'s #{dz_user.user.rigs.first.make}"

    RigInspection.create(
      rig: dz_user.user.reload.rigs.reload.first,
      form_template: operator.rig_inspection_template,
      inspected_by: instructors.first.user,
      membership: dz_user,
      is_ok: true,
      definition: operator.rig_inspection_template.definition,
    )

    # Add funds
    puts "-- Adding funds to account"
    (0..(Random.rand * 10).to_i).to_a.each do
      Transaction.create(
        membership: dz_user,
        status: :deposit,
        amount: ((Random.rand * 500) + 100).to_i,
      )
    end
  end

end
