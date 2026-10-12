# frozen_string_literal: true

require "rails_helper"

# P7.9: a load has one or more vehicles; with the multi_vehicle module any number carry or support
RSpec.describe LoadVehicle do
  include_context "operator"

  let(:gca) { create(:membership, operator: operator) }
  let(:pilot) { create(:membership, operator: operator) }
  let(:big) { create(:vehicle, operator: operator, capacity: 6, min_capacity: 2) }
  let(:small) { create(:vehicle, operator: operator, capacity: 3, min_capacity: 1) }
  let(:tug) { create(:vehicle, operator: operator, capacity: 1, kind: "tug") }

  # The crew a dropzone's load needs: a GCA, and a pilot for each vehicle that carries
  def build_load(entries)
    Load.new(operator: operator).tap do |record|
      record.vehicle_roles = entries
      roles = operator.crew_roles.index_by(&:key)
      record.crew_entries = [{ crew_role: roles.fetch("gca"), membership: gca }] +
                            record.carrying_load_vehicles.map { |lv| { crew_role: roles.fetch("pilot"), membership: pilot, load_vehicle: lv } }
    end
  end

  context "without the multi_vehicle module (skydiving)" do
    it "has exactly one vehicle, and it carries" do
      record = build_load([{ vehicle: big }])

      expect(record).to be_valid
      expect(record.vehicle).to eq(big)
      expect(record.capacity).to eq(6)
    end

    it "refuses a second vehicle and a support vehicle" do
      expect(build_load([{ vehicle: big }, { vehicle: small }])).not_to be_valid
      expect(build_load([{ vehicle: big }, { vehicle: tug, role: "support" }])).not_to be_valid
    end

    it "refuses a vehicle that only supports" do
      expect(build_load([{ vehicle: tug, role: "support" }])).not_to be_valid
    end

    it "keeps an aircraft on several loads of its queue, even when they are called" do
      first = create(:load, vehicle: big, dispatch_at: 10.minutes.from_now)
      second = create(:load, vehicle: big, dispatch_at: 40.minutes.from_now)

      expect(first.call).to be(true)
      expect(second.call).to be(true)
    end
  end

  context "with the multi_vehicle module" do
    before { operator.update!(modules: { multi_vehicle: true }) }

    it "adds up the seats of the vehicles that carry, and leaves out the ones that support" do
      record = build_load([{ vehicle: big }, { vehicle: small }, { vehicle: tug, role: "support" }])

      expect(record).to be_valid
      expect(record.capacity).to eq(9)
      expect(record.vehicle).to eq(big)
      expect(record.save).to be(true)
      expect(record.reload.load_vehicles.map(&:role)).to eq(%w(carrying carrying support))
      expect(record.available_slots).to eq(9)
    end

    it "needs one that carries" do
      expect(build_load([{ vehicle: tug, role: "support" }])).not_to be_valid
    end

    it "takes the vehicles of another operator for nothing" do
      foreign = create(:vehicle, operator: create(:operator))

      expect(build_load([{ vehicle: big }, { vehicle: foreign }])).not_to be_valid
    end

    it "replaces the vehicles and keeps the rows (and their slots) of the ones that stay" do
      record = build_load([{ vehicle: big }, { vehicle: small }]).tap(&:save!)
      kept = record.load_vehicles.find_by!(vehicle: big)

      record.vehicle_roles = [{ vehicle: small }, { vehicle: big, role: "carrying" }]
      record.save!

      expect(record.reload.load_vehicles.map(&:vehicle)).to eq([small, big])
      expect(record.load_vehicles.find_by!(vehicle: big)).to eq(kept)
    end

    describe "a vehicle goes with one load at a time" do
      let!(:first) { create(:load, vehicle: big, dispatch_at: 10.minutes.from_now).tap(&:call) }

      it "cannot be called while it is on another load that is called" do
        second = create(:load, vehicle: big, dispatch_at: 30.minutes.from_now)

        expect(second.call).to be(false)
        expect(second.errors.full_messages).to include("A vehicle is on another load that is called or on its way")
      end

      it "can be called when the other load has landed" do
        first.depart
        first.complete
        second = create(:load, vehicle: big, dispatch_at: 30.minutes.from_now)

        expect(second.call).to be(true)
      end

      it "is not held up by a load further away than the turnaround the operator sets" do
        operator.update!(settings: { vehicle_turnaround_minutes: 15 })
        near = create(:load, vehicle: big, dispatch_at: 20.minutes.from_now)
        far = create(:load, vehicle: big, dispatch_at: 60.minutes.from_now)

        expect(near.call).to be(false)
        expect(far.call).to be(true)
      end

      it "is not blocked by a load of a different vehicle" do
        other = create(:load, vehicle: small, dispatch_at: 12.minutes.from_now)

        expect(other.call).to be(true)
      end
    end
  end

  describe "slots in a vehicle" do
    before { operator.update!(modules: { multi_vehicle: true }) }

    let(:load_record) { build_load([{ vehicle: small }, { vehicle: big }, { vehicle: tug, role: "support" }]).tap(&:save!) }
    let(:small_row) { load_record.load_vehicles.find_by!(vehicle: small) }
    let(:big_row) { load_record.load_vehicles.find_by!(vehicle: big) }
    let(:tug_row) { load_record.load_vehicles.find_by!(vehicle: tug) }

    def slot_in(row, **attrs)
      member = create(:membership, operator: operator, credits: 500)
      Slot.new({
        load: load_record, membership: member, ticket_type: create(:ticket_type, operator: operator), body_mass_kg: 80,
        created_by: member, activity_type: ActivityType.allowed_for([member]).first, load_vehicle: row,
      }.merge(attrs))
    end

    it "counts against the vehicle and against the load" do
      slot_in(small_row).save!

      expect(small_row.reload.slots_count).to eq(1)
      expect(load_record.reload.slots_count).to eq(1)
      expect(small_row.available_slots).to eq(2)
    end

    it "stops at the seats of the vehicle while the load still has room" do
      3.times { slot_in(small_row).save! }
      full = slot_in(small_row)

      expect(full).not_to be_valid
      expect(full.errors.full_messages.join).to include("No slots available in #{small.name}")
      expect(slot_in(big_row)).to be_valid
    end

    it "cannot ride in a support vehicle or a vehicle of another load" do
      other_load = build_load([{ vehicle: big }]).tap(&:save!)

      expect(slot_in(tug_row)).not_to be_valid
      expect(slot_in(other_load.load_vehicles.first)).not_to be_valid
    end

    it "moves its count to the vehicle it changes to" do
      slot = slot_in(small_row).tap(&:save!)

      slot.update!(load_vehicle: big_row)

      expect(small_row.reload.slots_count).to eq(0)
      expect(big_row.reload.slots_count).to eq(1)
      expect(load_record.reload.slots_count).to eq(1)
    end

    it "can ride in none, as on a load with one vehicle" do
      expect(slot_in(nil)).to be_valid
    end
  end
end
