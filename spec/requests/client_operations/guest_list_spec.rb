# frozen_string_literal: true

require "rails_helper"

# P7.25: the client's DailyLog for an operator whose template keeps a guest list (whale watching): each passenger with a
# contact and an emergency contact, the crew by role, and the day as CSV; and the member's own emergency contact through
# UpdateUser.
RSpec.describe "Client operations: guest list" do
  let(:owner_user) { create(:user) }
  let(:operator) do
    Setup::Operators::CreateOperator.run!(owner: owner_user, industry: "whale_watching", name: "Whale watch", time_zone: "Australia/Brisbane",
                                          certification_body_ids: [])
  end
  let(:owner) { operator.memberships.owner.first }
  let(:skipper) { create(:membership, operator: operator, user: create(:user, name: "Skye Skipper"), user_role: operator.user_roles.find_by!(name: "skipper")) }
  let(:parent_user) { create(:user, name: "Morgan Parent", phone: "0400 333 444", emergency_contact: "Jo Parent 0400 333 555") }
  let(:parent) { create(:membership, operator: operator, user: parent_user, user_role: operator.user_roles.find_by!(name: "customer")) }
  let(:date) { Time.current.in_time_zone(operator.time_zone).to_date }

  let!(:trip) do
    boat = operator.vehicles.create!(name: "Ocean Spirit", registration: "WW-301", capacity: 40, kind: "boat")
    load = Load.new(operator: operator, max_slots: 40, state: "open", is_open: true, name: "Morning")
    load.vehicle = boat
    load.destination_ids = [operator.destinations.find_by!(name: "Bay run").id]
    load.crew_entries = [{ crew_role: operator.crew_roles.find_by!(key: "skipper"), membership: skipper }]
    load.save!
    Manifest::CreateSlot.run!(access_context: ApplicationInteraction::AccessContext.new(owner), load: load, membership: parent,
                              ticket_type: operator.ticket_types.find_by!(name: "Adult with child"), body_mass_kg: 70,
                              guests: [{ name: "Charlie Child", body_mass_kg: 22 }])
    load.update!(dispatch_at: date.in_time_zone(operator.time_zone).noon, state: "boarding")
    load
  end

  it "lists the passengers of the day with their contacts, the crew and the CSV" do
    json = client_operation("DailyLog", variables: { operatorId: operator.id, date: date.iso8601 }, as: owner_user)

    expect(json[:errors]).to be_nil
    entry = json.dig(:data, :dailyLog)
    expect(entry[:template]).to eq("guest_list")
    load = entry[:loads].sole
    expect(load).to include(loadNumber: trip.load_number, name: "Morning", destinations: ["Bay run"])
    expect(load[:crew].map { |crew| crew.to_h.symbolize_keys }).to eq([{ id: skipper.id.to_s, role: "Skipper", name: "Skye Skipper", phone: skipper.user.phone, vehicle: nil }])
    expect(load[:slots].map { |slot| slot.to_h.symbolize_keys.slice(:name, :phone, :emergencyContact, :ticketType, :escort) }).to eq(
      [
        { name: "Morgan Parent", phone: "0400 333 444", emergencyContact: "Jo Parent 0400 333 555", ticketType: "Adult with child", escort: nil },
        { name: "Charlie Child", phone: nil, emergencyContact: "Morgan Parent 0400 333 444", ticketType: "Adult with child", escort: "Morgan Parent" },
      ]
    )
    rows = CSV.parse(entry[:csv])
    expect(rows.first).to eq(["Trip", "Departure", "Name", "Phone", "Email", "Emergency contact", "Ticket", "With (adult)"])
    expect(rows.drop(1).pluck(2)).to eq(["Morgan Parent", "Charlie Child"])
  end

  it "does not give the guest list to a passenger" do
    json = client_operation("DailyLog", variables: { operatorId: operator.id, date: date.iso8601 }, as: parent_user)

    expect(json.dig(:data, :dailyLog)).to be_nil
  end

  it "stores a member's emergency contact" do
    json = client_operation("UpdateUser", variables: { membership: parent.id, emergencyContact: "Sam Parent 0400 999 000" }, as: parent_user)

    expect(json.dig(:data, :updateUser, :errors)).to be_nil
    expect(json.dig(:data, :updateUser, :membership, :user, :emergencyContact)).to eq("Sam Parent 0400 999 000")
    expect(parent_user.reload.emergency_contact).to eq("Sam Parent 0400 999 000")
  end
end
