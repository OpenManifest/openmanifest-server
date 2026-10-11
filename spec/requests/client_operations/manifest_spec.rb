# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Client operations: manifest" do
  include_context "dropzone"

  let(:owner_user) { create(:user) }
  let!(:owner) { create(:dropzone_user, dropzone: dropzone, user: owner_user, user_role: dropzone.user_roles.find_by(name: "owner"), credits: 500) }
  let!(:pilot) { create(:dropzone_user, dropzone: dropzone) }
  let!(:ticket_type) { create(:ticket_type, dropzone: dropzone, name: "Height", cost: 40) }
  let!(:tandem_ticket) { create(:ticket_type, dropzone: dropzone, name: "Tandem", cost: 200).tap { |t| t.update!(is_tandem: true, allow_manifesting_self: false) } }
  let(:load_variables) { { name: "Load A", plane: plane.id, pilot: pilot.id, gca: owner.id, maxSlots: 10 } }
  let!(:manifest_load) { create(:load, plane: plane, pilot: pilot, gca: owner, load_master: owner, name: "Existing", max_slots: 10) }

  before { fun_jumper.update!(credits: 300) }

  def slot_variables(dz_user, **extra)
    { load: manifest_load.id, dropzoneUser: dz_user.id, ticketType: ticket_type.id, jumpType: JumpType.allowed_for([dz_user]).first.id, exitWeight: 80 }.merge(extra)
  end

  def manifest!(dz_user, as: owner_user, **extra)
    json = client_operation("ManifestUser", variables: slot_variables(dz_user, **extra), as: as)
    Slot.find(json.dig(:data, :createSlot, :slot, :id))
  end

  describe "Loads" do
    it "lists the loads of the dropzone" do
      json = client_operation("Loads", variables: { dropzone: dropzone.id }, as: user)

      expect(json.dig(:data, :loads, :edges).map { |e| e.dig(:node, :id) }).to eq([manifest_load.id.to_s])
      expect(json.dig(:data, :loads, :edges, 0, :node)).to include(name: "Existing", state: "open", maxSlots: 10, availableSlots: 10)
    end

    it "filters by date in the dropzone's time zone" do
      old_load = create(:load, plane: plane, pilot: pilot, gca: owner, created_at: 3.days.ago)

      past = client_operation("Loads", variables: { dropzone: dropzone.id, date: 3.days.ago.in_time_zone(dropzone.time_zone).to_date.iso8601 }, as: user)
      today = client_operation("Loads", variables: { dropzone: dropzone.id, date: Time.current.in_time_zone(dropzone.time_zone).to_date.iso8601 }, as: user)
      unfiltered = client_operation("Loads", variables: { dropzone: dropzone.id }, as: user)

      expect(past.dig(:data, :loads, :edges).map { |e| e.dig(:node, :id) }).to eq([old_load.id.to_s])
      expect(today.dig(:data, :loads, :edges).map { |e| e.dig(:node, :id) }).to eq([manifest_load.id.to_s])
      # Without a date the resolver returns every load of the dropzone, not only today's
      expect(unfiltered.dig(:data, :loads, :edges).size).to eq(2)
    end

    it "requires authentication" do
      expect(client_operation("Loads", variables: { dropzone: dropzone.id }).dig(:errors, 0, :extensions, :code)).to eq("AUTHENTICATION_ERROR")
    end
  end

  describe "Load" do
    it "returns the load with plane, crew and slots" do
      manifest!(fun_jumper)

      json = client_operation("Load", variables: { id: manifest_load.id }, as: user)

      load = json.dig(:data, :load)
      expect(load).to include(id: manifest_load.id.to_s, name: "Existing", state: "open")
      expect(load.dig(:plane, :id)).to eq(plane.id.to_s)
      expect(load[:slots].map { |slot| slot.dig(:dropzoneUser, :id) }).to eq([fun_jumper.id.to_s])
    end

    it "returns the jumpers of a load that has no load master" do
      pending "BUG-091: Sources::Model#fetch drops nil keys, shifting the batched DropzoneUser results"
      no_master_load = create(:load, plane: plane, pilot: pilot, gca: owner, load_master: nil)
      manifest!(fun_jumper, load: no_master_load.id)

      json = client_operation("Load", variables: { id: no_master_load.id }, as: user)

      expect(json.dig(:data, :load, :slots).map { |slot| slot.dig(:dropzoneUser, :id) }).to eq([fun_jumper.id.to_s])
    end

    it "returns null for an unknown load" do
      expect(client_operation("Load", variables: { id: 0 }, as: user).dig(:data, :load)).to be_nil
    end
  end

  describe "CreateLoad" do
    it "creates a load as staff" do
      json = nil
      expect { json = client_operation("CreateLoad", variables: load_variables, as: owner_user) }.to change(Load, :count).by(1)

      expect(json.dig(:data, :createLoad, :errors)).to be_nil
      expect(json.dig(:data, :createLoad, :load)).to include(name: "Load A", state: "open", maxSlots: 10, loadNumber: 2)
      expect(json.dig(:data, :createLoad, :load, :pilot, :id)).to eq(pilot.id.to_s)
    end

    it "refuses a jumper without createLoad" do
      json = nil
      expect { json = client_operation("CreateLoad", variables: load_variables, as: user) }.not_to change(Load, :count)

      expect(json.dig(:data, :createLoad, :load)).to be_nil
      expect(json[:errors] || json.dig(:data, :createLoad, :errors)).to be_present
    end
  end

  describe "UpdateLoad" do
    it "gives a call by setting dispatchAt and boarding_call" do
      dispatch_at = 10.minutes.from_now.change(usec: 0)

      json = client_operation("UpdateLoad", variables: { id: manifest_load.id, attributes: { dispatchAt: dispatch_at.iso8601, state: "boarding_call" } }, as: owner_user)

      expect(json.dig(:data, :updateLoad, :errors)).to be_nil
      expect(json.dig(:data, :updateLoad, :load, :state)).to eq("boarding_call")
      expect(manifest_load.reload.dispatch_at).to eq(dispatch_at)
    end

    it "cancels a call by clearing dispatchAt and reopening the load" do
      manifest_load.update!(state: "boarding_call", dispatch_at: 10.minutes.from_now)

      json = client_operation("UpdateLoad", variables: { id: manifest_load.id, attributes: { dispatchAt: nil, state: "open" } }, as: owner_user)

      expect(json.dig(:data, :updateLoad, :load, :state)).to eq("open")
      expect(manifest_load.reload.dispatch_at).to be_nil
    end

    it "changes the plane" do
      other_plane = create(:plane, dropzone: dropzone, max_slots: 12)

      json = client_operation("UpdateLoad", variables: { id: manifest_load.id, attributes: { plane: other_plane.id } }, as: owner_user)

      expect(json.dig(:data, :updateLoad, :load, :plane, :id)).to eq(other_plane.id.to_s)
    end

    it "changes the maximum number of slots" do
      pending "BUG-025: check_max_slots is inverted, so any valid change of max slots is rejected"

      json = client_operation("UpdateLoad", variables: { id: manifest_load.id, attributes: { maxSlots: 12 } }, as: owner_user)

      expect(json.dig(:data, :updateLoad, :errors)).to be_nil
      expect(manifest_load.reload.max_slots).to eq(12)
    end

    it "refuses a jumper" do
      json = client_operation("UpdateLoad", variables: { id: manifest_load.id, attributes: { name: "Hijacked" } }, as: user)

      expect(manifest_load.reload.name).not_to eq("Hijacked")
      expect(json[:errors] || json.dig(:data, :updateLoad, :errors)).to be_present
    end

    it "only allows valid state transitions" do
      pending "BUG-035: the load state is taken directly from client input"
      manifest_load.update!(state: "landed")

      client_operation("UpdateLoad", variables: { id: manifest_load.id, attributes: { state: "boarding_call" } }, as: owner_user)

      expect(manifest_load.reload.state).to eq("landed")
    end
  end

  describe "ManifestUser" do
    it "manifests a member and charges their credits" do
      json = client_operation("ManifestUser", variables: slot_variables(fun_jumper), as: owner_user)

      expect(json.dig(:data, :createSlot, :errors)).to be_nil
      expect(json.dig(:data, :createSlot, :slot, :dropzoneUser, :id)).to eq(fun_jumper.id.to_s)
      expect(json.dig(:data, :createSlot, :slot, :cost)).to eq(40.0)
      expect(fun_jumper.reload.credits).to eq(260)
    end

    it "lets a jumper manifest themselves" do
      json = client_operation("ManifestUser", variables: slot_variables(fun_jumper), as: user)

      expect(json.dig(:data, :createSlot, :errors)).to be_nil
      expect(manifest_load.slots.map(&:dropzone_user)).to eq([fun_jumper])
    end

    it "rejects a jumper without enough credits" do
      fun_jumper.update!(credits: 10)

      json = client_operation("ManifestUser", variables: slot_variables(fun_jumper), as: user)

      expect(json.dig(:data, :createSlot, :errors)).to eq(["Not enough credits to manifest for this jump"])
      expect(manifest_load.slots).to be_empty
    end

    it "rejects manifesting the same person on a second open load" do
      manifest!(fun_jumper)
      second_load = create(:load, plane: plane, pilot: pilot, gca: owner)

      json = client_operation("ManifestUser", variables: slot_variables(fun_jumper, load: second_load.id), as: owner_user)

      expect(json.dig(:data, :createSlot, :errors).join).to match(/double-manifest/i)
    end

    it "manifests a tandem instructor with a passenger" do
      instructor.update!(credits: 500)

      json = client_operation("ManifestUser", variables: slot_variables(instructor, ticketType: tandem_ticket.id, passengerName: "Pat Passenger", passengerExitWeight: 70), as: owner_user)

      expect(json.dig(:data, :createSlot, :errors)).to be_nil
      expect(json.dig(:data, :createSlot, :slot, :ticketType, :isTandem)).to be(true)
      expect(json.dig(:data, :createSlot, :slot, :passengerName)).to eq("Pat Passenger")
      expect(manifest_load.slots.count).to eq(2)
    end

    it "does not let a student manifest another member" do
      student = create(:user)
      create(:dropzone_user, dropzone: dropzone, user: student, user_role: dropzone.user_roles.find_by(name: "student"), credits: 100)

      json = client_operation("ManifestUser", variables: slot_variables(fun_jumper), as: student)

      expect(json.dig(:data, :createSlot, :slot)).to be_nil
    end

    it "counts each slot once on the load" do
      manifest!(fun_jumper)

      expect(manifest_load.reload.slots_count).to eq(1)
    end

    it "stores the selected add-ons with the slot" do
      pending "BUG-028: extras are accepted but never stored or charged"
      extra = create(:extra, dropzone: dropzone, cost: 5) if FactoryBot.factories.registered?(:extra)
      extra ||= Extra.create!(dropzone: dropzone, name: "Video", cost: 5)
      ticket_type.extras << extra

      slot = manifest!(fun_jumper, extras: [extra.id])

      expect(slot.reload.extras).to eq([extra])
    end
  end

  describe "ManifestGroup" do
    let(:second) { create(:dropzone_user, dropzone: dropzone, credits: 300) }
    let(:group) { [{ id: fun_jumper.id, exitWeight: 80 }, { id: second.id, exitWeight: 75 }] }
    let(:group_variables) { { load: manifest_load.id, ticketType: ticket_type.id, jumpType: JumpType.allowed_for([fun_jumper, second]).first.id, userGroup: group } }

    it "manifests every member of the group" do
      json = client_operation("ManifestGroup", variables: group_variables, as: owner_user)

      expect(json.dig(:data, :createSlots, :errors)).to be_nil
      expect(manifest_load.slots.map(&:dropzone_user)).to match_array([fun_jumper, second])
    end

    it "rejects the whole group when a member cannot afford the jump" do
      second.update!(credits: 1)

      json = client_operation("ManifestGroup", variables: group_variables, as: owner_user)

      expect(json.dig(:data, :createSlots, :fieldErrors, 0)).to include(field: "credits")
      expect(json.dig(:data, :createSlots, :load)).to be_nil
      expect(manifest_load.slots).to be_empty
    end

    it "gives the group one group number" do
      pending "BUG-027: the group number is recomputed per member"
      client_operation("ManifestGroup", variables: group_variables, as: owner_user)

      expect(manifest_load.slots.pluck(:group_number).uniq.size).to eq(1)
    end
  end

  describe "MoveSlot" do
    let!(:second_load) { create(:load, plane: plane, pilot: pilot, gca: owner) }
    let!(:slot) { manifest!(fun_jumper) }

    it "moves a slot to another load of the dropzone" do
      json = client_operation("MoveSlot", variables: { sourceSlot: slot.id, targetLoad: second_load.id }, as: owner_user)

      expect(json.dig(:data, :moveSlot, :errors)).to be_nil
      expect(slot.reload.load).to eq(second_load)
    end

    it "keeps the slot when the target load is full" do
      second_load.update!(max_slots: 1)
      other = create(:dropzone_user, dropzone: dropzone, credits: 300)
      client_operation("ManifestUser", variables: slot_variables(other, load: second_load.id), as: owner_user)

      client_operation("MoveSlot", variables: { sourceSlot: slot.id, targetLoad: second_load.id }, as: owner_user)

      expect(slot.reload.load).to eq(manifest_load)
    end

    it "does not let a student move someone else's slot" do
      student = create(:user)
      create(:dropzone_user, dropzone: dropzone, user: student, user_role: dropzone.user_roles.find_by(name: "student"))

      client_operation("MoveSlot", variables: { sourceSlot: slot.id, targetLoad: second_load.id }, as: student)

      expect(slot.reload.load).to eq(manifest_load)
    end

    it "swaps with a target slot" do
      pending "BUG-031: moveSlot raises on the group_numner typo when a target slot is given"
      other = create(:dropzone_user, dropzone: dropzone, credits: 300)
      target = Slot.find(client_operation("ManifestUser", variables: slot_variables(other, load: second_load.id), as: owner_user).dig(:data, :createSlot, :slot, :id))

      client_operation("MoveSlot", variables: { sourceSlot: slot.id, targetSlot: target.id, targetLoad: second_load.id }, as: owner_user)

      expect(slot.reload.load).to eq(second_load)
      expect(target.reload.load).to eq(manifest_load)
    end
  end

  describe "DeleteSlot" do
    let!(:slot) { manifest!(fun_jumper) }

    it "removes the slot and refunds the jumper" do
      json = client_operation("DeleteSlot", variables: { id: slot.id }, as: owner_user)

      expect(json.dig(:data, :deleteSlot, :errors)).to be_nil
      expect(Slot.find_by(id: slot.id)).to be_nil
      expect(fun_jumper.reload.credits).to eq(300)
    end

    it "lets a jumper take themselves off the load" do
      client_operation("DeleteSlot", variables: { id: slot.id }, as: user)

      expect(Slot.find_by(id: slot.id)).to be_nil
    end

    it "refuses another jumper" do
      stranger = create(:user)
      create(:dropzone_user, dropzone: dropzone, user: stranger, user_role: dropzone.user_roles.find_by(name: "fun_jumper"))

      client_operation("DeleteSlot", variables: { id: slot.id }, as: stranger)

      expect(Slot.find_by(id: slot.id)).to be_present
    end

    it "deletes a slot that has no order" do
      pending "BUG-032: deleting a slot without an order fails with \"Order is required\""
      slot.order.destroy!
      slot.reload

      json = client_operation("DeleteSlot", variables: { id: slot.id }, as: owner_user)

      expect(json.dig(:data, :deleteSlot, :errors)).to be_nil
    end
  end

  describe "FinalizeLoad" do
    let!(:slot) { manifest!(fun_jumper) }

    it "lands the load" do
      json = client_operation("FinalizeLoad", variables: { id: manifest_load.id, state: "landed" }, as: owner_user)

      expect(json.dig(:data, :finalizeLoad, :errors)).to be_nil
      expect(json.dig(:data, :finalizeLoad, :load, :state)).to eq("landed")
      expect(slot.reload.order.state).to eq("completed")
    end

    it "cancels the load and refunds every slot" do
      json = client_operation("FinalizeLoad", variables: { id: manifest_load.id, state: "cancelled" }, as: owner_user)

      expect(json.dig(:data, :finalizeLoad, :load, :state)).to eq("cancelled")
      expect(fun_jumper.reload.credits).to eq(300)
    end

    it "refuses a jumper" do
      client_operation("FinalizeLoad", variables: { id: manifest_load.id, state: "landed" }, as: user)

      expect(manifest_load.reload.state).not_to eq("landed")
    end

    it "lands a load that has a tandem passenger" do
      pending "BUG-030: finalising raises for slots without an order (tandem passengers)"
      instructor.update!(credits: 500)
      client_operation("ManifestUser", variables: slot_variables(instructor, ticketType: tandem_ticket.id, passengerName: "Pat", passengerExitWeight: 70), as: owner_user)

      json = client_operation("FinalizeLoad", variables: { id: manifest_load.id, state: "landed" }, as: owner_user)

      expect(json.dig(:data, :finalizeLoad, :errors)).to be_nil
    end

    it "updates the jump counts of the jumpers when the load lands" do
      pending "BUG-026: update_counters! checks state_changed? after the save, which is always false"

      expect { client_operation("FinalizeLoad", variables: { id: manifest_load.id, state: "landed" }, as: owner_user) }.
        to change { fun_jumper.user.reload.jump_count }.by(1)
    end
  end
end
