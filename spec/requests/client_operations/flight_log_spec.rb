# frozen_string_literal: true

require "rails_helper"

# P7.26: the client's DailyLog for an operator whose template keeps a flight log (balloons): when the flight left and
# landed and how long it took, the balloon and its chase vehicle with what each did, and the crew of each; and the kind
# of a vehicle through CreateVehicle.
RSpec.describe "Client operations: flight log" do
  let(:owner_user) { create(:user) }
  let(:operator) do
    Setup::Operators::CreateOperator.run!(owner: owner_user, industry: "hot_air_balloon", name: "Balloons", time_zone: "Australia/Brisbane",
                                          certification_body_ids: [])
  end
  let(:owner) { operator.memberships.owner.first }
  let(:pilot) { create(:membership, operator: operator, user: create(:user, name: "Aria Pilot", body_mass_kg: 80), user_role: operator.user_roles.find_by!(name: "pilot")) }
  let(:chaser) { create(:membership, operator: operator, user: create(:user, name: "Cole Chaser"), user_role: operator.user_roles.find_by!(name: "chase_crew")) }
  let(:flyer) { create(:membership, operator: operator, user: create(:user, name: "Fay Flyer", date_of_birth: Date.new(1984, 7, 7)), user_role: operator.user_roles.find_by!(name: "customer")) }
  let(:date) { Time.current.in_time_zone(operator.time_zone).to_date }
  let(:balloon) { operator.vehicles.create!(name: "Sunrise", registration: "HB-201", capacity: 8, kind: "balloon", max_payload_kg: 720) }
  let(:chase) { operator.vehicles.create!(name: "Chase One", registration: "HB-202", capacity: 8, kind: "chase_vehicle") }

  let!(:flight) do
    load = Load.new(operator: operator, max_slots: 8, state: "open", is_open: true, name: "Dawn")
    load.vehicle_roles = [{ vehicle: balloon, role: "carrying" }, { vehicle: chase, role: "support" }]
    load.destination_ids = [operator.destinations.find_by!(name: "Valley field").id]
    load.crew_entries = [
      { crew_role: operator.crew_roles.find_by!(key: "pilot"), membership: pilot, vehicle: balloon },
      { crew_role: operator.crew_roles.find_by!(key: "chase_crew"), membership: chaser, vehicle: chase },
    ]
    load.save!
    Manifest::CreateSlot.run!(access_context: ApplicationInteraction::AccessContext.new(owner), load: load, membership: flyer,
                              ticket_type: operator.ticket_types.find_by!(name: "Adult"), body_mass_kg: 70)
    load.update!(dispatch_at: date.in_time_zone(operator.time_zone).change(hour: 6))
    load.call!
    load.depart!
    load.update!(departed_at: 50.minutes.ago)
    load.complete!
    load
  end

  it "logs the flight's times, its vehicles and the crew of each" do
    json = client_operation("DailyLog", variables: { operatorId: operator.id, date: date.iso8601 }, as: owner_user)

    expect(json[:errors]).to be_nil
    entry = json.dig(:data, :dailyLog)
    expect(entry[:template]).to eq("flight_log")
    load = entry[:loads].sole
    expect(load).to include(loadNumber: flight.load_number, name: "Dawn", durationMinutes: 50, destinations: ["Valley field"])
    expect(load.values_at(:departedAt, :completedAt)).to all(be_present)
    expect(load[:vehicles].map { |vehicle| vehicle.to_h.symbolize_keys.slice(:name, :kind, :role) }).to eq(
      [{ name: "Sunrise", kind: "balloon", role: "carrying" }, { name: "Chase One", kind: "chase_vehicle", role: "support" }]
    )
    expect(load[:crew].map { |crew| crew.to_h.symbolize_keys.slice(:role, :name, :vehicle) }).to eq(
      [{ role: "Pilot", name: "Aria Pilot", vehicle: "Sunrise" }, { role: "Chase crew", name: "Cole Chaser", vehicle: "Chase One" }]
    )
    expect(load[:slots].sole[:name]).to eq("Fay Flyer")
  end

  it "creates a vehicle of the kind chosen" do
    json = client_operation("CreateVehicle", variables: { attributes: { operatorId: operator.id, name: "Chase Two", registration: "HB-203", capacity: 6, kind: "chase_vehicle" } },
                                             as: owner_user)

    expect(json.dig(:data, :createVehicle, :errors)).to be_blank
    expect(json.dig(:data, :createVehicle, :vehicle)).to include(name: "Chase Two", kind: "chase_vehicle")
  end
end
