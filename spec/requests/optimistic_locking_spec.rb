# frozen_string_literal: true

require "rails_helper"

# BUG-024: two staff editing the same load or slot: the second save is refused with a CONFLICT instead of silently
# overwriting the first one
RSpec.describe "Optimistic locking" do
  include_context "dropzone"

  let(:owner_user) { create(:user) }
  let!(:owner) { create(:dropzone_user, dropzone: dropzone, user: owner_user, user_role: dropzone.user_roles.find_by(name: "owner"), credits: 500) }
  let!(:pilot) { create(:dropzone_user, dropzone: dropzone) }
  let!(:ticket_type) { create(:ticket_type, dropzone: dropzone, name: "Height", cost: 40) }
  let!(:plane_load) { create(:load, plane: plane, pilot: pilot, gca: owner, load_master: owner, name: "Original", max_slots: 10) }

  def graphql(query, variables, as: owner_user)
    post "/graphql", params: { query: query, variables: variables.to_json }, headers: as.create_new_auth_token
    response.parsed_body.with_indifferent_access
  end

  let(:update_load) do
    "mutation($id: ID!, $attributes: LoadInput!) { updateLoad(input: { id: $id, attributes: $attributes }) { errors load { id name lockVersion } } }"
  end

  def conflict?(json)
    json[:errors].to_a.any? { |error| error.dig(:extensions, :code) == "CONFLICT" }
  end

  describe "loads" do
    it "starts at version 0 and exposes it" do
      json = graphql("query($id: ID!) { load(id: $id) { lockVersion } }", { id: plane_load.id })

      expect(json.dig(:data, :load, :lockVersion)).to eq(0)
    end

    it "accepts an update from the current version and returns the next one" do
      json = graphql(update_load, { id: plane_load.id, attributes: { name: "Renamed", lockVersion: 0 } })

      expect(json.dig(:data, :updateLoad, :errors)).to be_nil
      expect(json.dig(:data, :updateLoad, :load)).to include(name: "Renamed", lockVersion: 1)
    end

    it "refuses an update from an older version, with the code CONFLICT, and changes nothing" do
      graphql(update_load, { id: plane_load.id, attributes: { name: "First", lockVersion: 0 } })

      json = graphql(update_load, { id: plane_load.id, attributes: { name: "Second", lockVersion: 0 } })

      expect(conflict?(json)).to be(true)
      expect(json[:errors].first[:message]).to eq("This load was changed by someone else")
      expect(plane_load.reload.name).to eq("First")
    end

    it "does not check without a version (older clients)" do
      graphql(update_load, { id: plane_load.id, attributes: { name: "First", lockVersion: 0 } })

      json = graphql(update_load, { id: plane_load.id, attributes: { name: "Second" } })

      expect(json[:errors]).to be_nil
      expect(plane_load.reload.name).to eq("Second")
    end

    it "is not bumped when somebody is manifested (the counters change, not the load)" do
      expect { client_operation("ManifestUser", variables: { load: plane_load.id, dropzoneUser: fun_jumper.id, ticketType: ticket_type.id, jumpType: JumpType.allowed_for([fun_jumper]).first.id, exitWeight: 80 }, as: owner_user) }.
        not_to(change { plane_load.reload.lock_version })
    end

    it "is bumped by a state change" do
      plane_load.update!(dispatch_at: 10.minutes.from_now)

      expect { plane_load.dispatch }.to change { plane_load.reload.lock_version }.by(1)
    end

    it "refuses landing a load from an old version" do
      stale = Load.find(plane_load.id)
      plane_load.update!(name: "Changed meanwhile")

      expect { stale.update!(name: "Mine") }.to raise_error(ActiveRecord::StaleObjectError)
    end

    it "does not make two taps on 'mark as landed' fail with an error" do
      plane_load.update!(dispatch_at: 10.minutes.from_now)
      plane_load.dispatch
      query = "mutation($id: Int!) { finalizeLoad(input: { id: $id, state: landed }) { errors load { state } } }"

      first = graphql(query, { id: plane_load.id })
      second = graphql(query, { id: plane_load.id })

      expect(first.dig(:data, :finalizeLoad, :load, :state)).to eq("landed")
      expect(second.dig(:data, :finalizeLoad, :errors)).to be_present
      expect(second[:errors]).to be_nil
    end
  end

  describe "slots" do
    before { fun_jumper.update!(credits: 300) }

    let!(:slot) do
      create(:slot, load: plane_load, dropzone: dropzone, dropzone_user: fun_jumper, ticket_type: ticket_type, exit_weight: 80,
                    jump_type: JumpType.allowed_for([fun_jumper]).first, created_by: owner)
    end
    let(:update_slot) do
      "mutation($id: Int!, $attributes: SlotInput!) { updateSlot(input: { id: $id, attributes: $attributes }) { errors slot { id exitWeight lockVersion } } }"
    end

    it "exposes the version" do
      json = graphql("query($id: ID!) { load(id: $id) { slots { lockVersion } } }", { id: plane_load.id })

      expect(json.dig(:data, :load, :slots, 0, :lockVersion)).to eq(0)
    end

    it "accepts an update from the current version" do
      json = graphql(update_slot, { id: slot.id, attributes: { exitWeight: 85, lockVersion: 0 } })

      expect(json.dig(:data, :updateSlot, :slot)).to include(exitWeight: 85.0, lockVersion: 1)
    end

    it "refuses an update from an older version" do
      graphql(update_slot, { id: slot.id, attributes: { exitWeight: 85, lockVersion: 0 } })

      json = graphql(update_slot, { id: slot.id, attributes: { exitWeight: 90, lockVersion: 0 } })

      expect(conflict?(json)).to be(true)
      expect(json[:errors].first[:message]).to eq("This slot was changed by someone else")
      expect(slot.reload.exit_weight).to eq(85)
    end

    it "refuses moving a slot that was changed meanwhile" do
      second_load = create(:load, plane: plane, pilot: pilot, gca: owner, max_slots: 10)
      stale = Slot.find(slot.id)
      slot.update!(exit_weight: 83)
      query = "mutation($source: Int!, $target: Int!) { moveSlot(input: { sourceSlot: $source, targetLoad: $target }) { errors } }"

      expect(stale.lock_version).to eq(0)
      json = graphql(query, { source: slot.id, target: second_load.id })

      # The mutation reads the slot itself, so it moves the current version
      expect(json[:errors]).to be_nil
      expect(slot.reload.load).to eq(second_load)
    end
  end
end
