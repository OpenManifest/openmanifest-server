# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Client operations: manifest" do
  include_context "operator"

  let(:owner_user) { create(:user) }
  let!(:owner) { create(:membership, operator: operator, user: owner_user, user_role: operator.user_roles.find_by(name: "owner"), credits: 500) }
  let!(:pilot) { create(:membership, operator: operator) }
  let!(:ticket_type) { create(:ticket_type, operator: operator, name: "Height", cost: 40) }
  let!(:tandem_ticket) { create(:ticket_type, operator: operator, name: "Tandem", cost: 200).tap { |t| t.update!(is_tandem: true, allow_manifesting_self: false) } }
  let(:load_variables) { { name: "Load A", vehicle: vehicle.id, pilot: pilot.id, gca: owner.id, maxSlots: 10 } }
  let!(:manifest_load) { create(:load, vehicle: vehicle, pilot: pilot, gca: owner, load_master: owner, name: "Existing", max_slots: 10) }

  before { fun_jumper.update!(credits: 300) }

  def slot_variables(dz_user, **extra)
    { load: manifest_load.id, membership: dz_user.id, ticketType: ticket_type.id, activityType: ActivityType.allowed_for([dz_user]).first.id, bodyMassKg: 80 }.merge(extra)
  end

  def manifest!(dz_user, as: owner_user, **extra)
    json = client_operation("ManifestUser", variables: slot_variables(dz_user, **extra), as: as)
    Slot.find(json.dig(:data, :createSlot, :slot, :id))
  end

  describe "Loads" do
    it "lists the loads of the operator" do
      json = client_operation("Loads", variables: { operator: operator.id }, as: user)

      expect(json.dig(:data, :loads, :edges).map { |e| e.dig(:node, :id) }).to eq([manifest_load.id.to_s])
      expect(json.dig(:data, :loads, :edges, 0, :node)).to include(name: "Existing", state: "open", maxSlots: 10, availableSlots: 10)
    end

    it "filters by date in the operator's time zone" do
      old_load = create(:load, vehicle: vehicle, pilot: pilot, gca: owner, created_at: 3.days.ago)

      past = client_operation("Loads", variables: { operator: operator.id, date: 3.days.ago.in_time_zone(operator.time_zone).to_date.iso8601 }, as: user)
      today = client_operation("Loads", variables: { operator: operator.id, date: Time.current.in_time_zone(operator.time_zone).to_date.iso8601 }, as: user)
      unfiltered = client_operation("Loads", variables: { operator: operator.id }, as: user)

      expect(past.dig(:data, :loads, :edges).map { |e| e.dig(:node, :id) }).to eq([old_load.id.to_s])
      expect(today.dig(:data, :loads, :edges).map { |e| e.dig(:node, :id) }).to eq([manifest_load.id.to_s])
      # Without a date the resolver returns every load of the operator, not only today's
      expect(unfiltered.dig(:data, :loads, :edges).size).to eq(2)
    end

    it "requires authentication" do
      expect(client_operation("Loads", variables: { operator: operator.id }).dig(:errors, 0, :extensions, :code)).to eq("AUTHENTICATION_ERROR")
    end
  end

  describe "Load" do
    it "returns the load with vehicle, crew and slots" do
      manifest!(fun_jumper)

      json = client_operation("Load", variables: { id: manifest_load.id }, as: user)

      load = json.dig(:data, :load)
      expect(load).to include(id: manifest_load.id.to_s, name: "Existing", state: "open")
      expect(load.dig(:vehicle, :id)).to eq(vehicle.id.to_s)
      expect(load[:slots].map { |slot| slot.dig(:membership, :id) }).to eq([fun_jumper.id.to_s])
    end

    it "returns the jumpers of a load that has no load master" do
      no_master_load = create(:load, vehicle: vehicle, pilot: pilot, gca: owner, load_master: nil)
      manifest!(fun_jumper, load: no_master_load.id)

      json = client_operation("Load", variables: { id: no_master_load.id }, as: user)

      expect(json.dig(:data, :load, :slots).map { |slot| slot.dig(:membership, :id) }).to eq([fun_jumper.id.to_s])
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

    it "ignores the state sent for a new load" do
      json = client_operation("CreateLoad", variables: load_variables.merge(state: "completed"), as: owner_user)

      expect(json.dig(:data, :createLoad, :load, :state)).to eq("open")
    end

    it "refuses a jumper without createLoad" do
      json = nil
      expect { json = client_operation("CreateLoad", variables: load_variables, as: user) }.not_to change(Load, :count)

      expect(json.dig(:data, :createLoad, :load)).to be_nil
      expect(json[:errors] || json.dig(:data, :createLoad, :errors)).to be_present
    end
  end

  describe "UpdateLoad" do
    it "gives a call by setting dispatchAt and boarding" do
      dispatch_at = 10.minutes.from_now.change(usec: 0)

      json = client_operation("UpdateLoad", variables: { id: manifest_load.id, attributes: { dispatchAt: dispatch_at.iso8601, state: "boarding" } }, as: owner_user)

      expect(json.dig(:data, :updateLoad, :errors)).to be_nil
      expect(json.dig(:data, :updateLoad, :load, :state)).to eq("boarding")
      expect(manifest_load.reload.dispatch_at).to eq(dispatch_at)
    end

    it "cancels a call by clearing dispatchAt and reopening the load" do
      manifest_load.update!(state: "boarding", dispatch_at: 10.minutes.from_now)

      json = client_operation("UpdateLoad", variables: { id: manifest_load.id, attributes: { dispatchAt: nil, state: "open" } }, as: owner_user)

      expect(json.dig(:data, :updateLoad, :load, :state)).to eq("open")
      expect(manifest_load.reload.dispatch_at).to be_nil
    end

    it "changes the vehicle" do
      other_vehicle = create(:vehicle, operator: operator, capacity: 12)

      json = client_operation("UpdateLoad", variables: { id: manifest_load.id, attributes: { vehicle: other_vehicle.id } }, as: owner_user)

      expect(json.dig(:data, :updateLoad, :load, :vehicle, :id)).to eq(other_vehicle.id.to_s)
    end

    it "changes the maximum number of slots" do
      json = client_operation("UpdateLoad", variables: { id: manifest_load.id, attributes: { maxSlots: 12 } }, as: owner_user)

      expect(json.dig(:data, :updateLoad, :errors)).to be_nil
      expect(manifest_load.reload.max_slots).to eq(12)
    end

    it "refuses fewer slots than are already manifested" do
      2.times { manifest!(create(:membership, operator: operator, credits: 300)) }

      json = client_operation("UpdateLoad", variables: { id: manifest_load.id, attributes: { maxSlots: 1 } }, as: owner_user)

      expect(json.dig(:data, :updateLoad, :errors).join).to match(/too many manifested/i)
      expect(manifest_load.reload.max_slots).to eq(10)
    end

    it "allows exactly as many slots as are manifested" do
      2.times { manifest!(create(:membership, operator: operator, credits: 300)) }

      json = client_operation("UpdateLoad", variables: { id: manifest_load.id, attributes: { maxSlots: 2 } }, as: owner_user)

      expect(json.dig(:data, :updateLoad, :errors)).to be_nil
      expect(manifest_load.reload.max_slots).to eq(2)
    end

    it "changes to a vehicle that seats exactly the manifested jumpers" do
      2.times { manifest!(create(:membership, operator: operator, credits: 300)) }
      small_vehicle = create(:vehicle, operator: operator, capacity: 2)

      json = client_operation("UpdateLoad", variables: { id: manifest_load.id, attributes: { vehicle: small_vehicle.id } }, as: owner_user)

      expect(json.dig(:data, :updateLoad, :errors)).to be_nil
      expect(manifest_load.reload.vehicle).to eq(small_vehicle)
    end

    it "refuses a jumper" do
      json = client_operation("UpdateLoad", variables: { id: manifest_load.id, attributes: { name: "Hijacked" } }, as: user)

      expect(manifest_load.reload.name).not_to eq("Hijacked")
      expect(json[:errors] || json.dig(:data, :updateLoad, :errors)).to be_present
    end

    it "only allows valid state transitions" do
      manifest_load.update!(state: "completed")

      json = client_operation("UpdateLoad", variables: { id: manifest_load.id, attributes: { state: "boarding" } }, as: owner_user)

      expect(manifest_load.reload.state).to eq("completed")
      expect(json.dig(:data, :updateLoad, :errors).join).to match(/can't go from completed to boarding/)
    end

    it "starts a boarding call with a call time and the state" do
      json = client_operation("UpdateLoad", variables: { id: manifest_load.id, attributes: { dispatchAt: 10.minutes.from_now.iso8601, state: "boarding" } }, as: owner_user)

      expect(json.dig(:data, :updateLoad, :errors)).to be_nil
      expect(json.dig(:data, :updateLoad, :load, :state)).to eq("boarding")
      expect(manifest_load.reload.dispatch_at).to be_present
    end

    it "starts a boarding call with only a call time" do
      client_operation("UpdateLoad", variables: { id: manifest_load.id, attributes: { dispatchAt: 10.minutes.from_now.iso8601 } }, as: owner_user)

      expect(manifest_load.reload.state).to eq("boarding")
    end

    it "refuses a boarding call without a call time" do
      json = client_operation("UpdateLoad", variables: { id: manifest_load.id, attributes: { state: "boarding" } }, as: owner_user)

      expect(json.dig(:data, :updateLoad, :errors)).to be_present
      expect(manifest_load.reload.state).to eq("open")
    end

    it "cancels the boarding call by clearing the call time" do
      manifest_load.update!(dispatch_at: 10.minutes.from_now)
      manifest_load.call

      json = client_operation("UpdateLoad", variables: { id: manifest_load.id, attributes: { dispatchAt: nil, state: "open" } }, as: owner_user)

      expect(json.dig(:data, :updateLoad, :errors)).to be_nil
      expect(manifest_load.reload).to have_attributes(state: "open", dispatch_at: nil)
    end

    it "accepts the state the load is already in" do
      json = client_operation("UpdateLoad", variables: { id: manifest_load.id, attributes: { dispatchAt: nil, state: "open" } }, as: owner_user)

      expect(json.dig(:data, :updateLoad, :errors)).to be_nil
      expect(manifest_load.reload.state).to eq("open")
    end

    it "re-opens a cancelled load" do
      manifest_load.cancel

      json = client_operation("UpdateLoad", variables: { id: manifest_load.id, attributes: { state: "open" } }, as: owner_user)

      expect(json.dig(:data, :updateLoad, :errors)).to be_nil
      expect(manifest_load.reload.state).to eq("open")
    end

    it "lands a load through the state, settling the orders and counting the jump once" do
      slot = manifest!(fun_jumper)
      manifest_load.update!(dispatch_at: 10.minutes.from_now)
      manifest_load.call

      expect { client_operation("UpdateLoad", variables: { id: manifest_load.id, attributes: { state: "completed" } }, as: owner_user) }.
        to change { fun_jumper.user.reload.load_count }.by(1)

      expect(manifest_load.reload.state).to eq("completed")
      expect(slot.reload.order.state).to eq("completed")
    end

    it "cancels a load through the state and refunds the jumpers" do
      manifest!(fun_jumper)

      client_operation("UpdateLoad", variables: { id: manifest_load.id, attributes: { state: "cancelled" } }, as: owner_user)

      expect(manifest_load.reload.state).to eq("cancelled")
      expect(fun_jumper.reload.credits).to eq(300)
    end

    it "does not take off a cancelled load" do
      manifest_load.cancel

      json = client_operation("UpdateLoad", variables: { id: manifest_load.id, attributes: { state: "departed" } }, as: owner_user)

      expect(json.dig(:data, :updateLoad, :errors)).to be_present
      expect(manifest_load.reload.state).to eq("cancelled")
    end
  end

  describe "ManifestUser" do
    it "manifests a member and charges their credits" do
      json = client_operation("ManifestUser", variables: slot_variables(fun_jumper), as: owner_user)

      expect(json.dig(:data, :createSlot, :errors)).to be_nil
      expect(json.dig(:data, :createSlot, :slot, :membership, :id)).to eq(fun_jumper.id.to_s)
      expect(json.dig(:data, :createSlot, :slot, :costCents)).to eq(4000)
      expect(fun_jumper.reload.credits).to eq(260)
    end

    it "lets a jumper manifest themselves" do
      json = client_operation("ManifestUser", variables: slot_variables(fun_jumper), as: user)

      expect(json.dig(:data, :createSlot, :errors)).to be_nil
      expect(manifest_load.slots.map(&:membership)).to eq([fun_jumper])
    end

    it "rejects a jumper without enough credits" do
      fun_jumper.update!(credits: 10)

      json = client_operation("ManifestUser", variables: slot_variables(fun_jumper), as: user)

      expect(json.dig(:data, :createSlot, :errors)).to eq(["Not enough credits to manifest for this jump"])
      expect(manifest_load.slots).to be_empty
    end

    it "rejects manifesting the same person on a second open load" do
      manifest!(fun_jumper)
      second_load = create(:load, vehicle: vehicle, pilot: pilot, gca: owner)

      json = client_operation("ManifestUser", variables: slot_variables(fun_jumper, load: second_load.id), as: owner_user)

      expect(json.dig(:data, :createSlot, :errors).join).to match(/double-manifest/i)
    end

    it "manifests a tandem instructor with a guest" do
      instructor.update!(credits: 500)

      json = client_operation("ManifestUser", variables: slot_variables(instructor, ticketType: tandem_ticket.id, guestName: "Pat Guest", guestBodyMassKg: 70), as: owner_user)

      expect(json.dig(:data, :createSlot, :errors)).to be_nil
      expect(json.dig(:data, :createSlot, :slot, :ticketType, :isTandem)).to be(true)
      expect(json.dig(:data, :createSlot, :slot, :guestName)).to eq("Pat Guest")
      expect(manifest_load.slots.count).to eq(2)
    end

    it "does not let a student manifest another member" do
      student = create(:user)
      create(:membership, operator: operator, user: student, user_role: operator.user_roles.find_by(name: "student"), credits: 100)

      json = client_operation("ManifestUser", variables: slot_variables(fun_jumper), as: student)

      expect(json.dig(:data, :createSlot, :slot)).to be_nil
    end

    it "counts each slot once on the load" do
      manifest!(fun_jumper)

      expect(manifest_load.reload.slots_count).to eq(1)
    end

    context "with add-ons" do
      let!(:video) { Extra.create!(operator: operator, name: "Video", cost: 5) }
      let!(:coach) { Extra.create!(operator: operator, name: "Coach", cost: 12) }
      let!(:unrelated) { Extra.create!(operator: operator, name: "Not on this ticket", cost: 1) }

      before { ticket_type.extras << [video, coach] }

      it "stores the selected add-ons with the slot" do
        slot = manifest!(fun_jumper, extras: [video.id])

        expect(slot.reload.extras).to eq([video])
      end

      it "stores every selected add-on" do
        slot = manifest!(fun_jumper, extras: [video.id, coach.id])

        expect(slot.reload.slot_extras.count).to eq(2)
        expect(slot.extras).to match_array([video, coach])
      end

      it "charges the ticket and the add-ons in one order" do
        slot = manifest!(fun_jumper, extras: [video.id, coach.id])

        expect(slot.reload.cost_cents).to eq(5700)
        expect(slot.order.amount).to eq(57)
        expect(fun_jumper.reload.credits).to eq(243)
      end

      it "refunds the add-ons with the ticket" do
        slot = manifest!(fun_jumper, extras: [video.id, coach.id])

        client_operation("DeleteSlot", variables: { id: slot.id }, as: owner_user)

        expect(fun_jumper.reload.credits).to eq(300)
      end

      it "counts the add-ons in the credit check" do
        fun_jumper.update!(credits: 50)

        json = client_operation("ManifestUser", variables: slot_variables(fun_jumper, extras: [video.id, coach.id]), as: owner_user)

        expect(json.dig(:data, :createSlot, :slot)).to be_nil
        expect(json.dig(:data, :createSlot, :fieldErrors).to_a.to_s + json.dig(:data, :createSlot, :errors).to_a.to_s).to match(/credits/i)
      end

      it "refuses an add-on that is not offered with the ticket" do
        json = client_operation("ManifestUser", variables: slot_variables(fun_jumper, extras: [unrelated.id]), as: owner_user)

        expect(json.dig(:data, :createSlot, :slot)).to be_nil
        expect(json.dig(:data, :createSlot, :fieldErrors, 0, :field)).to eq("extras")
        expect(Slot.where(membership: fun_jumper)).to be_empty
      end

      it "refuses an add-on of another operator" do
        foreign = Extra.create!(operator: create(:operator), name: "Video", cost: 5)

        json = client_operation("ManifestUser", variables: slot_variables(fun_jumper, extras: [foreign.id]), as: owner_user)

        expect(json.dig(:data, :createSlot, :slot)).to be_nil
      end

      it "manifests without add-ons as before" do
        slot = manifest!(fun_jumper)

        expect(slot.reload.extras).to be_empty
        expect(slot.order.amount).to eq(40)
      end
    end
  end

  describe "ManifestGroup" do
    let(:second) { create(:membership, operator: operator, credits: 300) }
    let(:group) { [{ id: fun_jumper.id, bodyMassKg: 80 }, { id: second.id, bodyMassKg: 75 }] }
    let(:group_variables) { { load: manifest_load.id, ticketType: ticket_type.id, activityType: ActivityType.allowed_for([fun_jumper, second]).first.id, userGroup: group } }

    it "manifests every member of the group" do
      json = client_operation("ManifestGroup", variables: group_variables, as: owner_user)

      expect(json.dig(:data, :createSlots, :errors)).to be_nil
      expect(manifest_load.slots.map(&:membership)).to match_array([fun_jumper, second])
    end

    it "rejects the whole group when a member cannot afford the jump" do
      second.update!(credits: 1)

      json = client_operation("ManifestGroup", variables: group_variables, as: owner_user)

      expect(json.dig(:data, :createSlots, :fieldErrors, 0)).to include(field: "credits")
      expect(json.dig(:data, :createSlots, :load)).to be_nil
      expect(manifest_load.slots).to be_empty
    end

    it "gives the group one group number" do
      client_operation("ManifestGroup", variables: group_variables, as: owner_user)

      expect(manifest_load.slots.pluck(:group_number).uniq.size).to eq(1)
    end

    it "gives a group of three one group number, and the next group the next one" do
      third = create(:membership, operator: operator, credits: 300)
      other_group = Array.new(2) { create(:membership, operator: operator, credits: 300) }
      [[fun_jumper, second, third], other_group].each do |members|
        variables = group_variables.merge(activityType: ActivityType.allowed_for(members).first.id, userGroup: members.map { |member| { id: member.id, bodyMassKg: 80 } })
        expect(client_operation("ManifestGroup", variables: variables, as: owner_user).dig(:data, :createSlots, :errors)).to be_blank
      end

      groups = manifest_load.slots.group_by(&:group_number).values.map { |slots| slots.map(&:membership) }
      expect(groups).to match_array([match_array([fun_jumper, second, third]), match_array(other_group)])
    end

    it "uses the group number the client gives" do
      client_operation("ManifestGroup", variables: group_variables.merge(groupNumber: 7), as: owner_user)

      expect(manifest_load.slots.pluck(:group_number)).to eq([7, 7])
    end

    it "charges the add-ons to every member of the group" do
      video = Extra.create!(operator: operator, name: "Video", cost: 5)
      ticket_type.extras << video

      client_operation("ManifestGroup", variables: group_variables.merge(extras: [video.id]), as: owner_user)

      expect(manifest_load.slots.map { |slot| slot.extras.to_a }).to all(eq([video]))
      expect([fun_jumper, second].map { |member| member.reload.credits }).to eq([255, 255])
    end

    it "counts the add-ons in the credit check of the group" do
      video = Extra.create!(operator: operator, name: "Video", cost: 5)
      ticket_type.extras << video
      second.update!(credits: 42)

      json = client_operation("ManifestGroup", variables: group_variables.merge(extras: [video.id]), as: owner_user)

      expect(json.dig(:data, :createSlots, :fieldErrors, 0)).to include(field: "credits")
      expect(manifest_load.slots).to be_empty
    end
  end

  describe "MoveSlot" do
    let!(:second_load) { create(:load, vehicle: vehicle, pilot: pilot, gca: owner) }
    let!(:slot) { manifest!(fun_jumper) }

    it "moves a slot to another load of the operator" do
      json = client_operation("MoveSlot", variables: { sourceSlot: slot.id, targetLoad: second_load.id }, as: owner_user)

      expect(json.dig(:data, :moveSlot, :errors)).to be_nil
      expect(slot.reload.load).to eq(second_load)
    end

    it "keeps the slot when the target load is full" do
      second_load.update!(max_slots: 1)
      other = create(:membership, operator: operator, credits: 300)
      client_operation("ManifestUser", variables: slot_variables(other, load: second_load.id), as: owner_user)

      client_operation("MoveSlot", variables: { sourceSlot: slot.id, targetLoad: second_load.id }, as: owner_user)

      expect(slot.reload.load).to eq(manifest_load)
    end

    it "does not let a student move someone else's slot" do
      student = create(:user)
      create(:membership, operator: operator, user: student, user_role: operator.user_roles.find_by(name: "student"))

      client_operation("MoveSlot", variables: { sourceSlot: slot.id, targetLoad: second_load.id }, as: student)

      expect(slot.reload.load).to eq(manifest_load)
    end

    it "moves a slot of a jumper whose credit balance is empty (nil)" do
      fun_jumper.update_columns(credits_cents: nil)

      json = client_operation("MoveSlot", variables: { sourceSlot: slot.id, targetLoad: second_load.id }, as: owner_user)

      expect(json.dig(:data, :moveSlot, :errors)).to be_nil
      expect(slot.reload.load).to eq(second_load)
    end

    it "moves next to a target slot, into its load and group" do
      other = create(:membership, operator: operator, credits: 300)
      target = Slot.find(client_operation("ManifestUser", variables: slot_variables(other, load: second_load.id), as: owner_user).dig(:data, :createSlot, :slot, :id))
      target.update_column(:group_number, 7)

      json = client_operation("MoveSlot", variables: { sourceSlot: slot.id, targetSlot: target.id, targetLoad: second_load.id }, as: owner_user)

      expect(json.dig(:data, :moveSlot, :errors)).to be_nil
      expect(slot.reload.load).to eq(second_load)
      expect(slot.group_number).to eq(7)
      expect(target.load).to eq(second_load)
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
      create(:membership, operator: operator, user: stranger, user_role: operator.user_roles.find_by(name: "fun_jumper"))

      client_operation("DeleteSlot", variables: { id: slot.id }, as: stranger)

      expect(Slot.find_by(id: slot.id)).to be_present
    end

    it "deletes a slot that has no order" do
      slot.order.destroy!
      slot.reload

      json = client_operation("DeleteSlot", variables: { id: slot.id }, as: owner_user)

      expect(json.dig(:data, :deleteSlot, :errors)).to be_nil
    end
  end

  describe "FinalizeLoad" do
    let!(:slot) { manifest!(fun_jumper) }

    it "lands the load" do
      json = client_operation("FinalizeLoad", variables: { id: manifest_load.id, state: "completed" }, as: owner_user)

      expect(json.dig(:data, :finalizeLoad, :errors)).to be_nil
      expect(json.dig(:data, :finalizeLoad, :load, :state)).to eq("completed")
      expect(slot.reload.order.state).to eq("completed")
    end

    it "cancels the load and refunds every slot" do
      json = client_operation("FinalizeLoad", variables: { id: manifest_load.id, state: "cancelled" }, as: owner_user)

      expect(json.dig(:data, :finalizeLoad, :load, :state)).to eq("cancelled")
      expect(fun_jumper.reload.credits).to eq(300)
    end

    it "lands a load only once" do
      client_operation("FinalizeLoad", variables: { id: manifest_load.id, state: "completed" }, as: owner_user)

      expect { client_operation("FinalizeLoad", variables: { id: manifest_load.id, state: "completed" }, as: owner_user) }.
        not_to(change { fun_jumper.user.reload.load_count })
    end

    it "does not cancel a completed load" do
      client_operation("FinalizeLoad", variables: { id: manifest_load.id, state: "completed" }, as: owner_user)

      json = client_operation("FinalizeLoad", variables: { id: manifest_load.id, state: "cancelled" }, as: owner_user)

      expect(json.dig(:data, :finalizeLoad, :errors).join).to match(/can't be cancelled/)
      expect(manifest_load.reload.state).to eq("completed")
      expect(fun_jumper.reload.credits).to eq(260)
    end

    it "refuses a jumper" do
      client_operation("FinalizeLoad", variables: { id: manifest_load.id, state: "completed" }, as: user)

      expect(manifest_load.reload.state).not_to eq("completed")
    end

    it "lands a load that has a tandem guest" do
      instructor.update!(credits: 500)
      client_operation("ManifestUser", variables: slot_variables(instructor, ticketType: tandem_ticket.id, guestName: "Pat", guestBodyMassKg: 70), as: owner_user)

      json = client_operation("FinalizeLoad", variables: { id: manifest_load.id, state: "completed" }, as: owner_user)

      expect(json.dig(:data, :finalizeLoad, :errors)).to be_nil
    end

    it "updates the jump counts of the jumpers when the load lands" do
      expect { client_operation("FinalizeLoad", variables: { id: manifest_load.id, state: "completed" }, as: owner_user) }.
        to change { fun_jumper.user.reload.load_count }.by(1)
    end
  end
end
