# frozen_string_literal: true

require "rails_helper"

# P7.10: crew roles are data of the operator; loads are validated from them
RSpec.describe CrewRole do
  let(:owner) { create(:user) }
  let(:dropzone) { Setup::Operators::CreateOperator.run!(owner: owner, industry: "skydiving", name: "DZ", time_zone: "Australia/Brisbane", federation: Federation.first) }
  let(:rafting) { Setup::Operators::CreateOperator.run!(owner: owner, industry: "generic", name: "Rafts", time_zone: "Australia/Brisbane") }

  describe "presets" do
    it "gives a dropzone a pilot per vehicle, a GCA and a load master per load" do
      roles = dropzone.crew_roles.ordered.map { |role| role.slice(:key, :scope, :required, :permission, :occupies_slot).symbolize_keys }

      expect(roles).to eq(
        [
          { key: "pilot", scope: "vehicle", required: true, permission: "actAsPilot", occupies_slot: false },
          { key: "gca", scope: "load", required: true, permission: "actAsGCA", occupies_slot: false },
          { key: "load_master", scope: "load", required: false, permission: "actAsLoadMaster", occupies_slot: false },
        ]
      )
    end

    it "gives a generic operator none, and does not add them twice" do
      expect(rafting.crew_roles).to be_empty
      expect { Presets::Apply.run!(operator: dropzone) }.not_to(change { dropzone.crew_roles.count })
    end
  end

  describe "validation" do
    it "has a key of lower case letters, unique per operator among the kept" do
      rafting.crew_roles.create!(key: "guide", name: "Guide")

      expect(rafting.crew_roles.new(key: "Guide!", name: "x")).not_to be_valid
      expect(rafting.crew_roles.new(key: "guide", name: "Second")).not_to be_valid
      expect(dropzone.crew_roles.new(key: "guide", name: "Guide")).to be_valid
      rafting.crew_roles.find_by!(key: "guide").discard
      expect(rafting.crew_roles.new(key: "guide", name: "Guide")).to be_valid
    end

    it "names a permission that exists" do
      expect(rafting.crew_roles.new(key: "guide", name: "Guide", permission: "actAsPilot")).to be_valid
      expect(rafting.crew_roles.new(key: "guide", name: "Guide", permission: "flyToTheMoon")).not_to be_valid
    end
  end

  describe "a load of a dropzone" do
    let(:vehicle) { create(:vehicle, operator: dropzone, capacity: 8, min_capacity: 1) }
    let(:pilot) { create(:membership, operator: dropzone).tap { |member| member.grant!(:actAsPilot) } }
    let(:gca) { create(:membership, operator: dropzone).tap { |member| member.grant!(:actAsGCA) } }

    it "needs a GCA and a pilot" do
      record = Load.new(operator: dropzone, vehicle: vehicle)

      expect(record).not_to be_valid
      expect(record.errors.full_messages).to contain_exactly("Every load needs a Pilot", "Every load needs a GCA")
    end

    it "takes them through pilot= and gca= and reads them back, before and after saving" do
      record = Load.new(operator: dropzone, vehicle: vehicle, pilot: pilot, gca: gca)

      expect(record.pilot).to eq(pilot)
      expect(record.save).to be(true)
      expect(record.reload).to have_attributes(pilot: pilot, gca: gca, load_master: nil)
      expect(record.crew_assignments.find_by!(crew_role: dropzone.crew_roles.find_by!(key: "pilot")).load_vehicle.vehicle).to eq(vehicle)
    end

    it "changes the pilot by assigning another" do
      record = create(:load, vehicle: vehicle, operator: dropzone, pilot: pilot, gca: gca)
      other = create(:membership, operator: dropzone)

      record.update!(pilot: other)

      expect(record.reload.pilot).to eq(other)
      expect(record.crew_assignments.count).to eq(2)
    end

    it "can leave the load master out, and is ready when everything is filled" do
      record = create(:load, vehicle: vehicle, operator: dropzone, pilot: pilot, gca: gca)

      expect(record.ready?).to be(false)
      record.update!(load_master: gca)
      record.update_columns(ready_slots_count: 1)
      expect(record.ready?).to be(true)
    end

    it "refuses a member of another operator" do
      stranger = create(:membership, operator: create(:operator))

      expect(Load.new(operator: dropzone, vehicle: vehicle, pilot: stranger, gca: gca)).not_to be_valid
    end

    it "checks the permission of the role when an interaction puts somebody on the crew" do
      member = create(:membership, operator: dropzone)
      record = Load.new(operator: dropzone, vehicle: vehicle, pilot: member, gca: gca)
      record.enforce_crew_permissions = true

      expect(record).not_to be_valid
      expect(record.errors.full_messages.join).to include("cannot act as Pilot")
    end
  end

  describe "a rafting operator" do
    before do
      rafting.crew_roles.create!(key: "guide", name: "Guide", scope: "vehicle", required: true, occupies_slot: true,
                                 vehicle_kinds: ["raft"], permission: "actAsPilot")
      rafting.crew_roles.create!(key: "ranger", name: "Ranger", scope: "load", required: false)
    end

    let(:rafts) { Array.new(3) { |n| create(:vehicle, operator: rafting, name: "Raft #{n + 1}", kind: "raft", capacity: 6) } }
    let(:tender) { create(:vehicle, operator: rafting, name: "Tender", kind: "chase", capacity: 2) }
    let(:guides) { Array.new(3) { create(:membership, operator: rafting).tap { |member| member.grant!(:actAsPilot) } } }
    let(:guide_role) { rafting.crew_roles.find_by!(key: "guide") }

    def build_load(crew: nil)
      Load.new(operator: rafting).tap do |record|
        record.vehicle_roles = rafts.map { |raft| { vehicle: raft } } + [{ vehicle: tender, role: "support" }]
        record.crew_entries = crew || rafts.each_with_index.map { |raft, n| { crew_role: guide_role, membership: guides[n], vehicle: raft } }
      end
    end

    it "needs a guide in each raft, and none in the vehicle that only supports" do
      expect(build_load).to be_valid
      missing = build_load(crew: [{ crew_role: guide_role, membership: guides[0], vehicle: rafts[0] }, { crew_role: guide_role, membership: guides[1], vehicle: rafts[1] }])

      expect(missing).not_to be_valid
      expect(missing.errors.full_messages).to eq(["Every load needs a Guide"])
    end

    it "keeps a guide to one raft" do
      record = build_load.tap(&:save!)

      expect(record.reload.crew_assignments.map { |assignment| assignment.load_vehicle.vehicle }).to match_array(rafts)
      twice = LoadCrewAssignment.new(load: record, crew_role: guide_role, membership: guides[0], load_vehicle: record.load_vehicles.find_by!(vehicle: rafts[0]))
      expect { twice.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "does not put a guide on the vehicle that supports, or on a load role without one" do
      support = build_load.load_vehicles.find(&:support?)
      record = build_load
      record.crew_entries = record.crew_assignments.map { |assignment| { crew_role: assignment.crew_role, membership: assignment.membership, load_vehicle: assignment.load_vehicle } } +
                            [{ crew_role: guide_role, membership: guides[0], load_vehicle: support }]

      expect(record).not_to be_valid
    end

    it "counts the guides, who have a seat in the raft, against the seats of the load" do
      record = build_load.tap(&:save!)

      expect(record.capacity).to eq(18)
      expect(record.crew_seats).to eq(3)
      expect(record.available_slots).to eq(15)
    end

    it "leaves a role without seat out of the count" do
      record = build_load.tap(&:save!)
      record.crew_assignments.build(crew_role: rafting.crew_roles.find_by!(key: "ranger"), membership: guides[0]).save!

      expect(record.reload.available_slots).to eq(15)
    end
  end
end
