# frozen_string_literal: true

require "rails_helper"

# BUG-019: slots_count must count each slot once, ready_slots_count must count the ready ones.
RSpec.describe Slot, "counter caches" do
  let(:dropzone) { create(:dropzone, credits: 0) }
  let(:plane) { create(:plane, dropzone: dropzone, max_slots: 14) }
  let(:plane_load) { create(:load, plane: plane) }
  let(:other_load) { create(:load, plane: plane) }

  def add_slot(load, **attrs)
    member = create(:dropzone_user, dropzone: dropzone, credits: 500)
    create(:slot, load: load, dropzone: dropzone, dropzone_user: member, jump_type: JumpType.allowed_for([member]).first, **attrs)
  end

  def counts(record)
    record.reload.slice(:slots_count, :ready_slots_count).symbolize_keys
  end

  it "counts a slot once and as ready" do
    add_slot(plane_load)

    expect(counts(plane_load)).to eq(slots_count: 1, ready_slots_count: 1)
  end

  it "counts every slot of a load once" do
    Array.new(3) { add_slot(plane_load) }

    expect(counts(plane_load)).to eq(slots_count: 3, ready_slots_count: 3)
    expect(plane_load.slots.count).to eq(3)
  end

  it "counts the slots of a dropzone once" do
    expect { Array.new(2) { add_slot(plane_load) } }.to change { dropzone.reload.slots_count }.by(2)
  end

  it "counts a tandem passenger's slot as a slot and as ready" do
    passenger = Passenger.create!(name: "Pat Passenger", exit_weight: 70, dropzone: dropzone)
    ticket_type = create(:ticket_type, dropzone: dropzone).tap { |t| t.update!(is_tandem: true) }
    jump_type = JumpType.first

    Slot.create!(load: plane_load, passenger: passenger, ticket_type: ticket_type, jump_type: jump_type, exit_weight: 70)

    expect(counts(plane_load)).to eq(slots_count: 1, ready_slots_count: 1)
  end

  it "decrements both counters when a slot is deleted" do
    slots = Array.new(2) { add_slot(plane_load) }

    slots.first.destroy!

    expect(counts(plane_load)).to eq(slots_count: 1, ready_slots_count: 1)
  end

  it "moves the counts with a slot to another load" do
    slot = add_slot(plane_load)

    slot.update!(load: other_load)

    expect(counts(plane_load)).to eq(slots_count: 0, ready_slots_count: 0)
    expect(counts(other_load)).to eq(slots_count: 1, ready_slots_count: 1)
  end

  it "does not count a slot as ready while nobody is manifested on it" do
    slot = add_slot(plane_load)

    slot.update_columns(dropzone_user_id: nil)
    Slot.counter_culture_fix_counts

    expect(counts(plane_load)).to eq(slots_count: 1, ready_slots_count: 0)
  end

  it "leaves available slots at max slots minus the slots on the load" do
    Array.new(4) { add_slot(plane_load) }

    expect(plane_load.reload.available_slots).to eq(10)
  end

  it "reports a load as ready once its ready slots reach the plane's minimum" do
    plane.update!(min_slots: 2)
    plane_load.update!(load_master: plane_load.gca)
    Array.new(2) { add_slot(plane_load) }

    expect(plane_load.reload).to be_ready
  end

  it "is repaired by counter_culture_fix_counts" do
    Array.new(2) { add_slot(plane_load) }
    plane_load.update_columns(slots_count: 4, ready_slots_count: 0)

    Slot.counter_culture_fix_counts

    expect(counts(plane_load)).to eq(slots_count: 2, ready_slots_count: 2)
  end
end
