# frozen_string_literal: true

require "rails_helper"

# P6.5: who may manifest and move whom (BUG-006, BUG-007, BUG-062, BUG-092)
RSpec.describe "Manifest authorization" do
  include_context "dropzone"

  let(:other_dropzone) { create(:dropzone, state: "public") }
  let(:other_plane) { create(:plane, dropzone: other_dropzone, max_slots: 16) }

  let!(:owner) { create(:dropzone_user, dropzone: dropzone, user: create(:user), user_role: dropzone.user_roles.find_by(name: "owner"), credits: 500) }
  let!(:pilot) { create(:dropzone_user, dropzone: dropzone) }
  let!(:ticket_type) { create(:ticket_type, dropzone: dropzone, name: "Height", cost: 40) }
  let!(:manifest_load) { create(:load, plane: plane, pilot: pilot, gca: owner, load_master: owner, max_slots: 10) }
  let!(:second_load) { create(:load, plane: plane, pilot: pilot, gca: owner, load_master: owner, max_slots: 10) }

  let(:student_user) { create(:user) }
  let!(:student) { create(:dropzone_user, dropzone: dropzone, user: student_user, user_role: dropzone.user_roles.find_by(name: "student"), credits: 300) }
  let(:manifest_user) { create(:user) }
  let!(:manifest_staff) { create(:dropzone_user, dropzone: dropzone, user: manifest_user, user_role: dropzone.user_roles.find_by(name: "manifest"), credits: 300) }
  let(:other_member) { create(:dropzone_user, dropzone: dropzone, credits: 300) }

  before { fun_jumper.update!(credits: 300) }

  def manifest(member, as:, load: manifest_load, **extra)
    client_operation("ManifestUser",
                     variables: {
                       load: load.id, dropzoneUser: member.id, ticketType: ticket_type.id,
                       jumpType: JumpType.allowed_for([member]).first.id, exitWeight: 80,
                     }.merge(extra),
                     as: as)
  end

  def manifest_group(members, as:)
    client_operation("ManifestGroup",
                     variables: {
                       load: manifest_load.id, ticketType: ticket_type.id, jumpType: JumpType.allowed_for(members).first.id,
                       userGroup: members.map { |member| { id: member.id, exitWeight: 80 } },
                     },
                     as: as)
  end

  describe "createSlot" do
    it "lets a member with createSlot manifest themselves" do
      expect(manifest(student, as: student_user).dig(:data, :createSlot, :slot, :id)).to be_present
    end

    it "refuses manifesting somebody else without createUserSlot" do
      json = manifest(fun_jumper, as: student_user)

      expect(json.dig(:data, :createSlot, :slot)).to be_nil
      expect(json.dig(:data, :createSlot, :errors, 0)).to include("createUserSlot")
      expect(Slot.where(load: manifest_load)).to be_empty
    end

    it "lets staff with createUserSlot manifest somebody else" do
      expect(manifest(fun_jumper, as: manifest_user).dig(:data, :createSlot, :slot, :id)).to be_present
    end

    it "refuses a member of another dropzone, and one who is not a member at all" do
      outsider = create(:user)
      other_owner = create(:user)
      create(:dropzone_user, dropzone: other_dropzone, user: other_owner, user_role: other_dropzone.user_roles.find_by(name: "owner"))

      expect(manifest(fun_jumper, as: outsider).dig(:data, :createSlot, :slot)).to be_nil
      expect(manifest(fun_jumper, as: other_owner).dig(:data, :createSlot, :slot)).to be_nil
      expect(Slot.where(load: manifest_load)).to be_empty
    end

    it "refuses a load of another dropzone for a member of this one" do
      foreign_load = create(:load, plane: other_plane, pilot: create(:dropzone_user, dropzone: other_dropzone),
                                   gca: create(:dropzone_user, dropzone: other_dropzone), max_slots: 10)

      json = manifest(fun_jumper, as: manifest_user, load: foreign_load)

      expect(json.dig(:data, :createSlot, :slot)).to be_nil
      expect(Slot.where(load: foreign_load)).to be_empty
    end

    it "refuses a ticket type of another dropzone" do
      foreign_ticket = create(:ticket_type, dropzone: other_dropzone, cost: 1)

      json = manifest(fun_jumper, as: manifest_user, ticketType: foreign_ticket.id)

      expect(json.dig(:data, :createSlot, :slot)).to be_nil
    end
  end

  describe "createSlots (groups)" do
    it "lets a member with createSlot manifest a group of only themselves" do
      expect(manifest_group([student], as: student_user).dig(:data, :createSlots, :load, :id)).to be_present
    end

    it "refuses a group with other people without createUserSlot" do
      json = manifest_group([student, fun_jumper], as: student_user)

      expect(json.dig(:data, :createSlots, :load)).to be_nil
      expect(json.dig(:data, :createSlots, :errors, 0)).to include("other people")
      expect(manifest_load.slots).to be_empty
    end

    it "lets staff with createUserSlot manifest a group they are not part of" do
      expect(manifest_group([fun_jumper, other_member], as: manifest_user).dig(:data, :createSlots, :load, :id)).to be_present
    end

    it "lets a member with createUserSlotWithSelf manifest a group they are part of, but not one they are not" do
      fun_jumper.grant!(:createUserSlotWithSelf)

      expect(manifest_group([other_member, fun_jumper], as: user).dig(:data, :createSlots, :load, :id)).to be_present
      second = create(:dropzone_user, dropzone: dropzone, credits: 300)
      refused = manifest_group([other_member.tap { |m| m.update!(credits: 300) }, second], as: user)
      expect(refused.dig(:data, :createSlots, :load)).to be_nil
    end

    it "refuses a stranger" do
      expect(manifest_group([fun_jumper], as: create(:user)).dig(:data, :createSlots, :load)).to be_nil
    end
  end

  describe "moveSlot" do
    let!(:slot) { Slot.find(manifest(fun_jumper, as: manifest_user).dig(:data, :createSlot, :slot, :id)) }

    def move(as:, target: second_load, source: slot)
      client_operation("MoveSlot", variables: { sourceSlot: source.id, targetLoad: target.id }, as: as)
    end

    it "lets a member with updateSlot move their own slot" do
      move(as: user)

      expect(slot.reload.load).to eq(second_load)
    end

    it "refuses moving your own slot without updateSlot" do
      student_slot = Slot.find(manifest(student, as: student_user).dig(:data, :createSlot, :slot, :id))

      move(as: student_user, source: student_slot)

      expect(student_slot.reload.load).to eq(manifest_load)
    end

    it "refuses moving somebody else's slot without updateUserSlot" do
      move(as: student_user)

      expect(slot.reload.load).to eq(manifest_load)
    end

    it "lets staff with updateUserSlot move somebody else's slot" do
      move(as: manifest_user)

      expect(slot.reload.load).to eq(second_load)
    end

    it "refuses a load of another dropzone, and a stranger" do
      foreign_load = create(:load, plane: other_plane, pilot: create(:dropzone_user, dropzone: other_dropzone),
                                   gca: create(:dropzone_user, dropzone: other_dropzone), max_slots: 10)

      move(as: manifest_user, target: foreign_load)
      move(as: create(:user))

      expect(slot.reload.load).to eq(manifest_load)
    end

    it "refuses a load that is full, one that has taken off and one that was cancelled" do
      second_load.update!(max_slots: 1)
      manifest(other_member, as: manifest_user, load: second_load)
      move(as: manifest_user)
      expect(slot.reload.load).to eq(manifest_load)

      second_load.update!(max_slots: 10)
      second_load.update_columns(state: Load.states[:in_flight])
      move(as: manifest_user)
      expect(slot.reload.load).to eq(manifest_load)

      second_load.update_columns(state: Load.states[:cancelled])
      move(as: manifest_user)
      expect(slot.reload.load).to eq(manifest_load)
    end
  end
end
