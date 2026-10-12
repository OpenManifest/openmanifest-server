# frozen_string_literal: true

require "rails_helper"

# BUG-020, BUG-021, BUG-023: two staff manifesting at the same time must not overbook a load, put one person on a load
# twice or overdraw a member's credits. The examples run real threads with their own database connections, so their data
# is committed (and deleted afterwards, see the :concurrent hook in rails_helper).
#
# Both requests are held back right after their own check has passed until the other has passed its check too (or half a
# second has gone by, which is what happens when the other request waits for a lock): without locking both pass.
RSpec.describe "Concurrent manifesting", :concurrent do
  let(:operator) { create(:operator, credits: 50) }
  let(:vehicle) { create(:vehicle, operator: operator, capacity: 14) }
  let(:ticket_type) { create(:ticket_type, operator: operator, cost: 100) }
  let(:staff) do
    create(:membership, operator: operator).tap do |staff|
      staff.grant! :createSlot
      staff.grant! :createUserSlot
      staff.grant! :updateUserSlot
    end
  end

  around do |example|
    reporting = Thread.report_on_exception
    Thread.report_on_exception = false
    example.run
  ensure
    Thread.report_on_exception = reporting
  end

  def member(credits: 500)
    create(:membership, operator: operator, credits: credits)
  end

  def create_load(max_slots: 14)
    create(:load, vehicle: vehicle, max_slots: max_slots)
  end

  # Holds each thread back after the check `method_name` of `klass` ran until the other thread ran the same check (the
  # first call of both together, then the second call of both, ...) or `timeout` seconds have gone by
  def rendezvous_after(method_name, klass = Slot, parties: 2, timeout: 0.5)
    latches = Hash.new { |hash, call| hash[call] = Concurrent::CountDownLatch.new(parties) }
    mutex = Mutex.new
    allow_any_instance_of(klass).to receive(method_name).and_wrap_original do |original, *args, &block|
      result = original.call(*args, &block)
      Thread.current[:rendezvous_calls] = Thread.current[:rendezvous_calls].to_i + 1
      latch = mutex.synchronize { latches[Thread.current[:rendezvous_calls]] }
      latch.count_down
      latch.wait(timeout)
      result
    end
  end

  # Manifests `membership` on `load` the way a staff member would, with records read inside the thread
  def manifest(load, membership)
    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        member = Membership.find(membership.id)
        Manifest::CreateSlot.run(
          access_context: access_context,
          load: Load.find(load.id),
          membership: member,
          ticket_type: TicketType.find(ticket_type.id),
          activity_type: ActivityType.allowed_for([member]).first,
          body_mass_kg: 80
        )
      end
    end.value
  end

  def access_context
    ApplicationInteraction::AccessContext.new(Membership.find(staff.id))
  end

  def manifest_group(load, memberships)
    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        members = memberships.map { |membership| Membership.find(membership.id) }
        Manifest::CreateMultipleSlots.run(
          access_context: access_context,
          load: Load.find(load.id),
          ticket_type: TicketType.find(ticket_type.id),
          activity_type: ActivityType.allowed_for(members).first,
          users: members.map { |membership| { membership: membership, body_mass_kg: 80.0 } }
        )
      end
    end.value
  end

  def move(slot, load)
    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        Manifest::MoveSlot.run(access_context: access_context, source_slot: Slot.find(slot.id), target_load: Load.find(load.id))
      end
    end.value
  end

  def concurrently(*jobs)
    jobs.map { |job| Thread.new { job.call } }.map(&:value)
  end

  it "does not overbook the last seat of a load" do
    vehicle_load = create_load(max_slots: 1)
    first = member
    second = member
    staff
    rendezvous_after(:available?)

    outcomes = concurrently(-> { manifest(vehicle_load, first) }, -> { manifest(vehicle_load, second) })

    expect(outcomes.count(&:valid?)).to eq(1)
    expect(vehicle_load.slots.count).to eq(1)
    expect(vehicle_load.reload.slots_count).to eq(1)
  end

  it "does not drive the credits of a member negative" do
    first_load = create_load
    second_load = create_load
    jumper = member(credits: 100)
    operator.update!(settings: operator.settings.merge("allow_double_manifesting" => true))
    staff
    rendezvous_after(:affordable?)

    outcomes = concurrently(-> { manifest(first_load, jumper) }, -> { manifest(second_load, jumper) })

    expect(outcomes.count(&:valid?)).to eq(1)
    expect(jumper.reload.credits).to eq(0)
    expect(Slot.where(membership: jumper).count).to eq(1)
  end

  it "puts one person on a load once" do
    vehicle_load = create_load
    jumper = member
    staff
    rendezvous_after(:available?)

    concurrently(-> { manifest(vehicle_load, jumper) }, -> { manifest(vehicle_load, jumper) })

    expect(Slot.where(load: vehicle_load, membership: jumper).count).to eq(1)
    expect(vehicle_load.reload.slots_count).to eq(1)
  end

  it "does not overbook a load with two groups" do
    vehicle_load = create_load(max_slots: 3)
    groups = Array.new(2) { Array.new(2) { member } }
    staff
    rendezvous_after(:available?)

    outcomes = concurrently(-> { manifest_group(vehicle_load, groups[0]) }, -> { manifest_group(vehicle_load, groups[1]) })

    expect(outcomes.count(&:valid?)).to eq(1)
    expect(vehicle_load.slots.count).to eq(2)
    expect(vehicle_load.reload.slots_count).to eq(2)
  end

  it "does not overbook a load when two slots are moved onto it" do
    source_load = create_load
    target_load = create_load(max_slots: 1)
    members = Array.new(2) { member }
    staff
    slots = members.map { |membership| manifest(source_load, membership) }.map(&:result)
    rendezvous_after(:open_with_room, Manifest::MoveSlot)

    outcomes = concurrently(-> { move(slots[0], target_load) }, -> { move(slots[1], target_load) })

    expect(outcomes.count(&:valid?)).to eq(1)
    expect(target_load.slots.count).to eq(1)
    expect(target_load.reload.slots_count).to eq(1)
    expect(source_load.reload.slots_count).to eq(1)
  end
end
