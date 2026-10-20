# frozen_string_literal: true

require "rails_helper"

# BUG-019: slots_count must count each slot once, ready_slots_count must count the ready ones.
RSpec.describe Slot, "counter caches" do
  let(:operator) { create(:operator, credits: 0) }
  let(:vehicle) { create(:vehicle, operator: operator, capacity: 14) }
  let(:vehicle_load) { create(:load, vehicle: vehicle) }
  let(:other_load) { create(:load, vehicle: vehicle) }

  def add_slot(load, **attrs)
    member = create(:membership, operator: operator, credits: 500)
    create(:slot, load: load, operator: operator, membership: member, activity_type: ActivityType.allowed_for([member]).first, **attrs)
  end

  def counts(record)
    record.reload.slice(:slots_count, :ready_slots_count).symbolize_keys
  end

  it "counts a slot once and as ready" do
    add_slot(vehicle_load)

    expect(counts(vehicle_load)).to eq(slots_count: 1, ready_slots_count: 1)
  end

  it "counts every slot of a load once" do
    Array.new(3) { add_slot(vehicle_load) }

    expect(counts(vehicle_load)).to eq(slots_count: 3, ready_slots_count: 3)
    expect(vehicle_load.slots.count).to eq(3)
  end

  it "counts the slots of an operator once" do
    expect { Array.new(2) { add_slot(vehicle_load) } }.to change { operator.reload.slots_count }.by(2)
  end

  it "counts a tandem guest's slot as a slot and as ready" do
    guest = Guest.create!(name: "Pat Guest", body_mass_kg: 70, operator: operator)
    ticket_type = create(:ticket_type, operator: operator).tap { |t| t.update!(requires_escort: true) }
    activity_type = ActivityType.first

    Slot.create!(load: vehicle_load, guest: guest, ticket_type: ticket_type, activity_type: activity_type, body_mass_kg: 70)

    expect(counts(vehicle_load)).to eq(slots_count: 1, ready_slots_count: 1)
  end

  it "decrements both counters when a slot is deleted" do
    slots = Array.new(2) { add_slot(vehicle_load) }

    slots.first.destroy!

    expect(counts(vehicle_load)).to eq(slots_count: 1, ready_slots_count: 1)
  end

  it "moves the counts with a slot to another load" do
    slot = add_slot(vehicle_load)

    slot.update!(load: other_load)

    expect(counts(vehicle_load)).to eq(slots_count: 0, ready_slots_count: 0)
    expect(counts(other_load)).to eq(slots_count: 1, ready_slots_count: 1)
  end

  it "does not count a slot as ready while nobody is manifested on it" do
    slot = add_slot(vehicle_load)

    slot.update_columns(membership_id: nil)
    Slot.counter_culture_fix_counts

    expect(counts(vehicle_load)).to eq(slots_count: 1, ready_slots_count: 0)
  end

  it "leaves available slots at max slots minus the slots on the load" do
    Array.new(4) { add_slot(vehicle_load) }

    expect(vehicle_load.reload.available_slots).to eq(10)
  end

  it "reports a load as ready once its ready slots reach the vehicle's minimum" do
    vehicle.update!(min_capacity: 2)
    vehicle_load.update!(load_master: vehicle_load.gca)
    Array.new(2) { add_slot(vehicle_load) }

    expect(vehicle_load.reload).to be_ready
  end

  it "is repaired by counter_culture_fix_counts" do
    Array.new(2) { add_slot(vehicle_load) }
    vehicle_load.update_columns(slots_count: 4, ready_slots_count: 0)

    Slot.counter_culture_fix_counts

    expect(counts(vehicle_load)).to eq(slots_count: 2, ready_slots_count: 2)
  end
end
