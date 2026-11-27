# frozen_string_literal: true

require "rails_helper"

# P7.26: the scenic-flight and hot-air-balloon templates, both on the aviation base. Scenic flights fly a helicopter or an
# aeroplane on a route, within each passenger's body-mass limit and what the aircraft may carry; balloon flights leave
# from a launch site with a chase vehicle (a support vehicle) and its crew, within age and body-mass limits. Both keep the
# flight log, with the times each flight left and landed.
RSpec.describe "Scenic-flight and hot-air-balloon templates" do
  let(:owner) { create(:user) }

  def create_operator(industry)
    Setup::Operators::CreateOperator.run!(owner: owner, industry: industry, name: "Test #{industry}", time_zone: "Australia/Brisbane")
  end

  def member(operator, role: "customer", **attributes)
    user = create(:user, date_of_birth: Date.new(1985, 1, 1), **attributes)
    create(:membership, operator: operator, user: user, user_role: operator.user_roles.find_by!(name: role), certification_level: nil).reload
  end

  def vehicle(operator, kind, **attributes)
    operator.vehicles.create!(name: "#{kind.humanize} #{operator.vehicles.count + 1}", registration: "V#{operator.vehicles.count + 1}", capacity: 4, kind: kind, **attributes)
  end

  def manifest(operator, flight, membership, ticket: "Adult", body_mass_kg: 80, guests: nil)
    Manifest::CreateSlot.run(
      access_context: ApplicationInteraction::AccessContext.new(operator.memberships.owner.first),
      load: flight, membership: membership, ticket_type: operator.ticket_types.find_by!(name: ticket), body_mass_kg: body_mass_kg, guests: guests
    )
  end

  # Called, gone and back through the load's events (which record when it left and landed)
  def fly(flight, minutes: 0)
    flight.update!(dispatch_at: 30.minutes.from_now)
    flight.call!
    flight.depart!
    flight.update!(departed_at: minutes.minutes.ago) if minutes.positive?
    flight.complete!
  end

  describe "the templates" do
    it "can be chosen, both on the aviation base, with the flight log as their daily log" do
      expect(Industry.slugs).to include("scenic_flights", "hot_air_balloon")
      expect(Industry.fetch("scenic_flights")).to have_attributes(extends: "_aviation", family: "_aviation", icon: "helicopter", daily_log_template: "flight_log",
                                                                  vehicle_kinds: %w(helicopter aeroplane), call_schedule_minutes: [30, 15])
      expect(Industry.fetch("hot_air_balloon")).to have_attributes(extends: "_aviation", family: "_aviation", icon: "airballoon", daily_log_template: "flight_log",
                                                                   vehicle_kinds: %w(balloon chase_vehicle), call_schedule_minutes: [60, 30])
    end

    it "keeps certifications and gear off, the limits, flight times and flight log on, and several vehicles for balloons" do
      scenic = Industry.fetch("scenic_flights").modules
      balloon = Industry.fetch("hot_air_balloon").modules
      expect(scenic.keys).to include("destinations", "escorts", "crew", "limits", "flight_times", "daily_log")
      expect(scenic.keys).not_to include("certifications", "activities", "equipment", "multi_vehicle")
      expect(scenic["limits"]).to eq("mass" => true, "payload" => true)
      expect(scenic.dig("destinations", "kinds")).to eq(["route"])
      expect(balloon.keys).to include("multi_vehicle", "flight_times", "daily_log", "escorts")
      expect(balloon["limits"]).to eq("mass" => true, "payload" => true, "age" => true)
      expect(balloon.dig("destinations", "kinds")).to eq(["site"])
      expect(CertificationBody.for_industry("scenic_flights")).to be_empty
    end

    it "names the aviation states for every aviation template, the dropzone keeping its own" do
      expect(Industry.fetch("scenic_flights").terminology.dig("state", "completed", "one")).to eq("Landed")
      expect(Industry.fetch("hot_air_balloon").terminology.dig("vehicle_kind", "chase_vehicle", "one")).to eq("Chase vehicle")
      expect(Industry.fetch("skydiving").terminology.dig("state", "boarding", "one")).to eq("Boarding call")
    end
  end

  describe "a scenic-flight operator" do
    let(:operator) { create_operator("scenic_flights") }
    # The pilot's own body mass counts towards what the aircraft carries
    let(:pilot) { member(operator, role: "pilot", body_mass_kg: 80) }
    let(:route) { operator.destinations.find_by!(name: "Coastal loop") }

    def flight(aircraft)
      flight = Load.new(operator: operator, max_slots: aircraft.capacity, state: "open", is_open: true, name: "Scenic")
      flight.vehicle = aircraft
      flight.destination_ids = [route.id]
      flight.crew_entries = [{ crew_role: operator.crew_roles.find_by!(key: "pilot"), membership: pilot, vehicle: aircraft }]
      flight.save!
      flight
    end

    it "gets the presets: a pilot per aircraft, routes and tickets with a body-mass limit" do
      expect(operator.vehicle_kinds).to eq(%w(helicopter aeroplane))
      expect(operator.crew_roles.ordered.map { |role| [role.key, role.scope, role.required, role.permission] }).to eq([["pilot", "vehicle", true, "actAsPilot"]])
      expect(route.kind).to eq("route")
      expect(operator.ticket_types.pluck(:name)).to contain_exactly("Adult", "Adult with child")
      expect(operator.ticket_types.find_by!(name: "Adult").participant_limits).to eq("max_body_mass_kg" => 135)
      expect(operator.terminology.dig("load", "one")).to eq("Flight")
      expect(operator.daily_logs.at(Date.current).template).to eq("flight_log")
    end

    it "needs a pilot for its aircraft" do
      flight = Load.new(operator: operator, max_slots: 3, state: "open", is_open: true, name: "Scenic")
      flight.vehicle = vehicle(operator, "helicopter", max_payload_kg: 300)
      expect(flight).not_to be_valid
      expect(flight.errors.full_messages).to include("Every load needs a Pilot")
    end

    it "keeps a passenger off when the helicopter would carry more than its payload, the pilot included" do
      helicopter = vehicle(operator, "helicopter", capacity: 3, max_payload_kg: 300)
      scenic = flight(helicopter)
      expect(manifest(operator, scenic, member(operator), body_mass_kg: 90)).to be_valid
      expect(manifest(operator, scenic, member(operator), body_mass_kg: 90)).to be_valid

      over = manifest(operator, scenic, member(operator, name: "Pax Three"), body_mass_kg: 60)
      expect(over).not_to be_valid
      expect(over.errors.full_messages.join).to match(/can carry at most 300/)
      expect(manifest(operator, scenic, member(operator), body_mass_kg: 40)).to be_valid
      expect(scenic.reload.slots_count).to eq(3)
    end

    it "keeps a passenger over the ticket's body-mass limit off, and asks for the body mass" do
      scenic = flight(vehicle(operator, "aeroplane", capacity: 5, max_payload_kg: 450))
      heavy = manifest(operator, scenic, member(operator, name: "Big Sky"), body_mass_kg: 140)
      expect(heavy).not_to be_valid
      expect(heavy.errors.full_messages.join).to match(/Big Sky must weigh at most 135/)
      expect(manifest(operator, scenic, member(operator), ticket: "Adult with child", guests: [{ name: "Kid", body_mass_kg: 30 }])).to be_valid
    end

    it "logs when the flight left and landed, its pilot, aircraft and passengers" do
      helicopter = vehicle(operator, "helicopter", capacity: 3, max_payload_kg: 300)
      scenic = flight(helicopter)
      expect(manifest(operator, scenic, member(operator, name: "Tara Tourist"))).to be_valid
      fly(scenic, minutes: 40)

      log = operator.daily_logs.at(scenic.reload.dispatch_at.in_time_zone(operator.time_zone).to_date)
      entry = log.generate_json.fetch(:loads).sole
      expect(entry.values_at(:departed_at, :completed_at)).to all(be_present)
      expect(entry.values_at(:duration_minutes, :destinations)).to eq([40, ["Coastal loop"]])
      expect(entry[:vehicle].values_at(:name, :kind)).to eq([helicopter.name, "helicopter"])
      expect(entry[:crew].map { |crew| crew.values_at(:role, :name, :vehicle) }).to eq([["Pilot", pilot.user.name, helicopter.name]])
      expect(entry[:slots].pluck(:name)).to eq(["Tara Tourist"])
    end
  end

  describe "a balloon operator" do
    let(:operator) { create_operator("hot_air_balloon") }
    let(:pilot) { member(operator, role: "pilot", name: "Aria Pilot", body_mass_kg: 80) }
    let(:chaser) { member(operator, role: "chase_crew", name: "Cole Chaser", body_mass_kg: 90) }
    let(:balloon) { vehicle(operator, "balloon", capacity: 8, max_payload_kg: 400) }
    let(:chase) { vehicle(operator, "chase_vehicle", capacity: 8) }
    let(:site) { operator.destinations.find_by!(name: "Valley field") }
    let(:pilot_role) { operator.crew_roles.find_by!(key: "pilot") }
    let(:chase_role) { operator.crew_roles.find_by!(key: "chase_crew") }

    def flight(crew: { pilot_role => [pilot, :balloon], chase_role => [chaser, :chase] })
      flight = Load.new(operator: operator, max_slots: 8, state: "open", is_open: true, name: "Dawn")
      flight.vehicle_roles = [{ vehicle: balloon, role: "carrying" }, { vehicle: chase, role: "support" }]
      flight.destination_ids = [site.id]
      flight.crew_entries = crew.map { |role, (membership, which)| { crew_role: role, membership: membership, vehicle: which == :balloon ? balloon : chase } }
      flight
    end

    it "gets the presets: a pilot for the balloon, chase crew for the chase vehicle, launch sites, age and body-mass limits" do
      expect(operator.crew_roles.ordered.map { |role| [role.key, role.scope, role.required, role.vehicle_kinds] }).
        to eq([["pilot", "vehicle", true, ["balloon"]], ["chase_crew", "vehicle", false, ["chase_vehicle"]]])
      expect(site.kind).to eq("site")
      expect(operator.ticket_types.find_by!(name: "Adult").participant_limits).to eq("min_age" => 8, "max_body_mass_kg" => 127)
      expect(operator.module?(:multi_vehicle)).to be true
      expect(operator.terminology.dig("destination", "one")).to eq("Launch site")
    end

    it "flies a balloon with its chase vehicle and crew; the balloon needs a pilot, the chase vehicle none" do
      dawn = flight
      expect(dawn).to be_valid
      dawn.save!
      expect(dawn.capacity).to eq(8)
      expect(dawn.crew_assignments.map { |assignment| [assignment.crew_role.key, assignment.load_vehicle.vehicle.kind] }).
        to contain_exactly(["pilot", "balloon"], ["chase_crew", "chase_vehicle"])

      expect(flight(crew: { chase_role => [chaser, :chase] })).not_to be_valid
      expect(flight(crew: { pilot_role => [pilot, :balloon] })).to be_valid
      # The pilot's role is the balloon's, not the chase vehicle's
      expect(flight(crew: { pilot_role => [pilot, :chase] })).not_to be_valid
    end

    it "keeps a child under the age limit off, takes one over it, and stops at the balloon's payload (the pilot aboard, the chase crew not)" do
      dawn = flight.tap(&:save!)
      young = manifest(operator, dawn, member(operator), ticket: "Adult with child", guests: [{ name: "Tot", date_of_birth: 5.years.ago.to_date, body_mass_kg: 20 }])
      expect(young).not_to be_valid
      expect(young.errors.full_messages.join).to match(/Tot must be at least 8 years old/)
      expect(manifest(operator, dawn, member(operator), ticket: "Adult with child", guests: [{ name: "Ivy", date_of_birth: 10.years.ago.to_date, body_mass_kg: 34 }])).to be_valid
      # 80 (the pilot) + 80 + 34 + 120 = 314 kg in the basket
      expect(manifest(operator, dawn, member(operator), body_mass_kg: 120)).to be_valid
      heavy = manifest(operator, dawn, member(operator, name: "Big Basket"), body_mass_kg: 130)
      expect(heavy.errors.full_messages.join).to match(/Big Basket must weigh at most 127/)
      expect(manifest(operator, dawn, member(operator), body_mass_kg: 90).errors.full_messages.join).to match(/can carry at most 400/)
      expect(manifest(operator, dawn, member(operator), body_mass_kg: 86)).to be_valid
    end

    it "logs the flight's times, both vehicles and the crew of each" do
      dawn = flight.tap(&:save!)
      expect(manifest(operator, dawn, member(operator, name: "Fay Flyer"))).to be_valid
      fly(dawn)

      entry = operator.daily_logs.at(dawn.reload.dispatch_at.in_time_zone(operator.time_zone).to_date).generate_json.fetch(:loads).sole
      expect(entry.values_at(:departed_at, :completed_at)).to all(be_present)
      expect(entry.values_at(:duration_minutes, :destinations)).to eq([0, ["Valley field"]])
      expect(entry[:vehicles].map { |row| row.values_at(:name, :kind, :role) }).to eq([[balloon.name, "balloon", "carrying"], [chase.name, "chase_vehicle", "support"]])
      expect(entry[:crew].map { |crew| crew.values_at(:role, :name, :vehicle) }).to eq([["Pilot", "Aria Pilot", balloon.name], ["Chase crew", "Cole Chaser", chase.name]])
    end
  end

  describe "vehicle kinds" do
    let(:operator) { create_operator("hot_air_balloon") }

    it "are the operator's: the main one by default, another one it runs, not one it does not" do
      expect(operator.vehicles.create!(name: "Basket", registration: "B", capacity: 8).kind).to eq("balloon")
      expect(operator.vehicles.create!(name: "Ute", registration: "U", capacity: 4, kind: "chase_vehicle").kind).to eq("chase_vehicle")
      expect(operator.vehicles.new(name: "Boat", registration: "X", capacity: 4, kind: "boat")).not_to be_valid
    end

    it "can be chosen when a vehicle is created" do
      outcome = Setup::Vehicles::CreateVehicle.run(access_context: ApplicationInteraction::AccessContext.new(operator.memberships.owner.first),
                                                   name: "Chase Two", registration: "C2", capacity: 6, kind: "chase_vehicle")
      expect(outcome).to be_valid
      expect(outcome.result.kind).to eq("chase_vehicle")
    end
  end

  describe "the demo operators" do
    it "give the scenic-flight operator a helicopter and an aeroplane with their payloads" do
      operator = create_operator("scenic_flights")
      expect(Demo::DataGenerator.run(operator: operator)).to be_valid
      expect(operator.vehicles.order(:id).map { |row| [row.name, row.kind, row.max_payload_kg.to_i] }).to eq([["Kestrel", "helicopter", 300], ["Skylark", "aeroplane", 450]])
      expect(operator.memberships.joins(:user_role).pluck("user_roles.name")).to include("pilot", "customer")
    end

    it "give the balloon operator a balloon, a chase vehicle, a pilot and chase crew" do
      operator = create_operator("hot_air_balloon")
      Demo::Generators::TemplateOperator.run!(operator: operator, email_prefix: "spec-")
      expect(operator.vehicles.order(:id).pluck(:name, :kind)).to eq([["Sunrise", "balloon"], ["Chase One", "chase_vehicle"]])
      expect(User.find_by!(email: "spec-cole.chaser@example.com").memberships.sole.user_role.name).to eq("chase_crew")
      expect(Guest.where(operator: operator).pluck(:name)).to eq(["Ivy Young"])
    end
  end
end
