# frozen_string_literal: true

require "rails_helper"

# P7.8: destinations, in both scopes (per slot: skydiving; per load: everyone else)
RSpec.describe Destination do
  let(:owner) { create(:user) }
  let(:skydiving) { Setup::Operators::CreateOperator.run!(owner: owner, industry: "skydiving", name: "DZ", time_zone: "Australia/Brisbane", federation: Federation.first) }
  let(:boats) { Setup::Operators::CreateOperator.run!(owner: owner, industry: "generic", name: "Boats", time_zone: "Australia/Brisbane") }

  describe "presets" do
    it "gives a skydiving operator the two usual altitudes in metres" do
      expect(skydiving.destinations.order(:altitude_m).pluck(:name, :altitude_m, :kind)).to eq(
        [["Hop n Pop", 1219.2, "altitude"], ["Full altitude", 4267.2, "altitude"]]
      )
    end

    it "gives a generic operator none" do
      expect(boats.destinations).to be_empty
    end

    it "does not add them again" do
      expect { Presets::Apply.run!(operator: skydiving) }.not_to(change { skydiving.destinations.count })
    end
  end

  describe "validation" do
    it "needs a height for an altitude" do
      destination = skydiving.destinations.new(kind: "altitude", name: "Wingsuit")

      expect(destination).not_to be_valid
      expect(destination.errors[:altitude_m]).to be_present
    end

    it "takes the height in feet" do
      destination = skydiving.destinations.create!(name: "Ten", altitude_ft: 10_000)

      expect(destination.altitude_m).to eq(3048)
      expect(destination.altitude_ft).to eq(10_000)
    end

    it "only takes the kinds of the template" do
      expect(skydiving.destinations.new(kind: "site", name: "Reef")).not_to be_valid
      expect(boats.destinations.new(kind: "altitude", altitude_m: 100, name: "High")).not_to be_valid
      expect(boats.destinations.new(kind: "site", name: "Reef", location: { lat: -16.9, lng: 145.8, max_depth_m: 18 })).to be_valid
      expect(boats.destinations.new(kind: "route", name: "Airport run", stops: %w(Airport Hotel))).to be_valid
    end

    it "keeps names apart per operator, archived ones excluded" do
      boats.destinations.create!(kind: "site", name: "Reef")

      expect(boats.destinations.new(kind: "site", name: "Reef")).not_to be_valid
      expect(skydiving.destinations.new(kind: "altitude", altitude_m: 10, name: "Reef")).to be_valid

      boats.destinations.find_by!(name: "Reef").discard
      expect(boats.destinations.new(kind: "site", name: "Reef")).to be_valid
    end

    it "does not belong to the operator's list once archived, and no ticket defaults to it any more" do
      destination = Destination.altitude_for(skydiving, 14_000)
      ticket = create(:ticket_type, operator: skydiving, default_destination: destination)

      destination.discard

      expect(skydiving.destinations).not_to include(destination)
      expect(ticket.reload.default_destination).to be_nil
    end
  end

  describe ".altitude_for" do
    it "finds the destination at that height or creates it, named by height" do
      expect(described_class.altitude_for(skydiving, 14_000).name).to eq("Full altitude")
      expect { described_class.altitude_for(skydiving, 14_000) }.not_to(change { skydiving.destinations.count })
      expect(described_class.altitude_for(skydiving, 10_000)).to have_attributes(name: "10000 ft", altitude_m: 3048)
    end
  end

  describe "ticket types" do
    it "default to a destination of their own operator only" do
      foreign = Destination.altitude_for(create(:operator), 14_000)

      expect(skydiving.ticket_types.new(name: "Mix", default_destination: foreign)).not_to be_valid
    end
  end

  describe "slots, per slot" do
    let(:operator) { skydiving }
    let(:member) { create(:membership, operator: operator, credits: 500) }
    let(:vehicle) { create(:vehicle, operator: operator, capacity: 8) }
    let(:load_record) { create(:load, vehicle: vehicle) }
    let(:hop) { operator.destinations.find_by!(name: "Hop n Pop") }
    let(:ticket) { create(:ticket_type, operator: operator, name: "Height") }

    def slot(**attrs)
      defaults = {
        load: load_record, membership: member, ticket_type: ticket, body_mass_kg: 80, created_by: member,
        activity_type: ActivityType.allowed_for([member]).first,
      }
      Slot.new(defaults.merge(attrs))
    end

    it "go where their ticket type goes by default" do
      created = slot.tap(&:save!)

      expect(created.destination.altitude_ft).to eq(14_000)
    end

    it "can go somewhere else than their ticket type" do
      created = slot(destination: hop).tap(&:save!)

      expect(created.destination).to eq(hop)
      expect(created.to_daily_log[:altitude]).to eq(4000)
    end

    it "need a destination" do
      ticket.update!(default_destination: nil)

      record = slot
      expect(record).not_to be_valid
      expect(record.errors[:destination]).to be_present
    end

    it "cannot go to another operator's destination" do
      foreign = Destination.altitude_for(create(:operator), 14_000)

      expect(slot(destination: foreign)).not_to be_valid
    end
  end

  describe "loads, per load" do
    let(:operator) { boats }
    let(:captain) { operator.memberships.owner.first }
    let(:vehicle) { operator.vehicles.create!(name: "Boat 1", capacity: 6, kind: "vehicle") }
    let!(:reef) { operator.destinations.create!(kind: "site", name: "Reef") }
    let!(:wreck) { operator.destinations.create!(kind: "site", name: "Wreck") }
    let(:load_record) { Load.create!(operator: operator, vehicle: vehicle, gca: captain, pilot: captain, max_slots: 6) }

    it "visits its destinations in order" do
      load_record.update!(destination_ids: [wreck.id, reef.id])

      expect(load_record.reload.destinations).to eq([wreck, reef])
    end

    it "takes a new list over the old one" do
      load_record.update!(destination_ids: [wreck.id, reef.id])
      load_record.update!(destination_ids: [reef.id])

      expect(load_record.reload.destinations).to eq([reef])
      expect(LoadDestination.where(load: load_record).count).to eq(1)
    end

    it "cannot be called without a destination" do
      load_record.dispatch_at = 10.minutes.from_now

      expect(load_record.call).to be(false)
      expect(load_record.errors[:destinations]).to be_present
      expect(load_record.reload.state).to eq("open")
    end

    it "can be called with one" do
      load_record.update!(destination_ids: [reef.id], dispatch_at: 10.minutes.from_now)

      expect(load_record.call).to be(true)
      expect(load_record.reload.state).to eq("boarding")
    end

    it "cannot visit another operator's destination" do
      foreign = create(:operator).destinations.create!(kind: "altitude", altitude_m: 100, name: "Elsewhere")

      expect(load_record.update(destination_ids: [foreign.id])).to be(false)
    end

    it "does not need one when the operator's destinations are per slot" do
      sky_load = create(:load, vehicle: create(:vehicle, operator: skydiving), dispatch_at: 10.minutes.from_now)

      expect(sky_load.call).to be(true)
    end
  end
end
