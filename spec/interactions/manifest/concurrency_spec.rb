# frozen_string_literal: true

require "rails_helper"

# BUG-020, BUG-021, BUG-023: two staff manifesting at the same time must not overbook a load, put one person on a load
# twice or overdraw a member's credits. The examples run real threads with their own database connections, so their data
# is committed (and deleted afterwards, see the :concurrent hook in rails_helper).
#
# Both requests are held back right after their own check has passed until the other has passed its check too (or half a
# second has gone by, which is what happens when the other request waits for a lock): without locking both pass.
RSpec.describe "Concurrent manifesting", :concurrent do
  let(:dropzone) { create(:dropzone, credits: 50) }
  let(:plane) { create(:plane, dropzone: dropzone, max_slots: 14) }
  let(:ticket_type) { create(:ticket_type, dropzone: dropzone, cost: 100) }
  let(:staff) do
    create(:dropzone_user, dropzone: dropzone).tap do |staff|
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
    create(:dropzone_user, dropzone: dropzone, credits: credits)
  end

  def create_load(max_slots: 14)
    create(:load, plane: plane, max_slots: max_slots)
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

  # Manifests `dropzone_user` on `load` the way a staff member would, with records read inside the thread
  def manifest(load, dropzone_user)
    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        member = DropzoneUser.find(dropzone_user.id)
        Manifest::CreateSlot.run(
          access_context: access_context,
          load: Load.find(load.id),
          dropzone_user: member,
          ticket_type: TicketType.find(ticket_type.id),
          jump_type: JumpType.allowed_for([member]).first,
          exit_weight: 80
        )
      end
    end.value
  end

  def access_context
    ApplicationInteraction::AccessContext.new(DropzoneUser.find(staff.id))
  end

  def manifest_group(load, dropzone_users)
    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        members = dropzone_users.map { |dropzone_user| DropzoneUser.find(dropzone_user.id) }
        Manifest::CreateMultipleSlots.run(
          access_context: access_context,
          load: Load.find(load.id),
          ticket_type: TicketType.find(ticket_type.id),
          jump_type: JumpType.allowed_for(members).first,
          users: members.map { |dropzone_user| { dropzone_user: dropzone_user, exit_weight: 80.0 } }
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
    plane_load = create_load(max_slots: 1)
    first = member
    second = member
    staff
    rendezvous_after(:available?)

    outcomes = concurrently(-> { manifest(plane_load, first) }, -> { manifest(plane_load, second) })

    expect(outcomes.count(&:valid?)).to eq(1)
    expect(plane_load.slots.count).to eq(1)
    expect(plane_load.reload.slots_count).to eq(1)
  end

  it "does not drive the credits of a member negative" do
    first_load = create_load
    second_load = create_load
    jumper = member(credits: 100)
    dropzone.update!(settings: dropzone.settings.merge("allow_double_manifesting" => true))
    staff
    rendezvous_after(:affordable?)

    outcomes = concurrently(-> { manifest(first_load, jumper) }, -> { manifest(second_load, jumper) })

    expect(outcomes.count(&:valid?)).to eq(1)
    expect(jumper.reload.credits).to eq(0)
    expect(Slot.where(dropzone_user: jumper).count).to eq(1)
  end

  it "puts one person on a load once" do
    plane_load = create_load
    jumper = member
    staff
    rendezvous_after(:available?)

    concurrently(-> { manifest(plane_load, jumper) }, -> { manifest(plane_load, jumper) })

    expect(Slot.where(load: plane_load, dropzone_user: jumper).count).to eq(1)
    expect(plane_load.reload.slots_count).to eq(1)
  end

  it "does not overbook a load with two groups" do
    plane_load = create_load(max_slots: 3)
    groups = Array.new(2) { Array.new(2) { member } }
    staff
    rendezvous_after(:available?)

    outcomes = concurrently(-> { manifest_group(plane_load, groups[0]) }, -> { manifest_group(plane_load, groups[1]) })

    expect(outcomes.count(&:valid?)).to eq(1)
    expect(plane_load.slots.count).to eq(2)
    expect(plane_load.reload.slots_count).to eq(2)
  end

  it "does not overbook a load when two slots are moved onto it" do
    source_load = create_load
    target_load = create_load(max_slots: 1)
    members = Array.new(2) { member }
    staff
    slots = members.map { |dropzone_user| manifest(source_load, dropzone_user) }.map(&:result)
    rendezvous_after(:open_with_room, Manifest::MoveSlot)

    outcomes = concurrently(-> { move(slots[0], target_load) }, -> { move(slots[1], target_load) })

    expect(outcomes.count(&:valid?)).to eq(1)
    expect(target_load.slots.count).to eq(1)
    expect(target_load.reload.slots_count).to eq(1)
    expect(source_load.reload.slots_count).to eq(1)
  end
end
