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

  # UB.1: a dropzone can switch off self-manifesting; the manifest desk does everything
  describe "when the dropzone does not allow self-manifesting" do
    let(:desk_message) { "Manifesting is done by the manifest desk at this dropzone" }
    let!(:own_slot) { Slot.find(manifest(fun_jumper, as: manifest_user).dig(:data, :createSlot, :slot, :id)) }
    let(:permissions_query) { "query($id: ID!) { dropzoneUser(id: $id) { permissions } }" }

    def permissions_of(member)
      post "/graphql", params: { query: permissions_query, variables: { id: member.id }.to_json }, headers: owner.user.create_new_auth_token
      response.parsed_body.dig("data", "dropzoneUser", "permissions")
    end

    before do
      fun_jumper.grant!(:updateSlot)
      fun_jumper.grant!(:deleteSlot)
      dropzone.update!(settings: { allow_self_manifest: false })
    end

    it "refuses a member manifesting themselves, with the manifest desk message" do
      json = manifest(student, as: student_user)

      expect(json.dig(:data, :createSlot, :slot)).to be_nil
      expect(json.dig(:data, :createSlot, :errors, 0)).to eq(desk_message)
    end

    it "refuses a member manifesting a group of only themselves" do
      other = create(:load, plane: plane, pilot: pilot, gca: owner, max_slots: 10)
      json = client_operation("ManifestGroup",
                              variables: {
                                load: other.id, ticketType: ticket_type.id,
                                jumpType: JumpType.allowed_for([student]).first.id,
                                userGroup: [{ id: student.id, exitWeight: 80 }],
                              },
                              as: student_user)

      expect(json.dig(:data, :createSlots, :load)).to be_nil
      expect(json.dig(:data, :createSlots, :errors, 0)).to eq(desk_message)
    end

    it "refuses a member taking themselves off a load" do
      json = client_operation("DeleteSlot", variables: { id: own_slot.id }, as: user)

      expect(json.dig(:data, :deleteSlot, :slot)).to be_nil
      expect(json.dig(:data, :deleteSlot, :errors, 0)).to eq(desk_message)
      expect(Slot.exists?(own_slot.id)).to be(true)
    end

    it "refuses a member editing their own slot" do
      post "/graphql",
           params: {
             query: "mutation($id: Int!) { updateSlot(input: { id: $id, attributes: { exitWeight: 90 } }) { slot { id } errors } }",
             variables: { id: own_slot.id }.to_json,
           },
           headers: user.create_new_auth_token
      json = response.parsed_body.with_indifferent_access

      expect(json.dig(:data, :updateSlot, :errors, 0)).to eq(desk_message)
      expect(own_slot.reload.exit_weight).to eq(80)
    end

    it "refuses a member moving their own slot" do
      json = client_operation("MoveSlot", variables: { sourceSlot: own_slot.id, targetLoad: second_load.id }, as: user)

      expect(json.dig(:data, :moveSlot, :errors, 0)).to eq(desk_message)
      expect(own_slot.reload.load).to eq(manifest_load)
    end

    it "lets manifest staff manifest, move, edit and take off a jumper, and manifest themselves" do
      moved = client_operation("MoveSlot", variables: { sourceSlot: own_slot.id, targetLoad: second_load.id }, as: manifest_user)
      expect(moved.dig(:data, :moveSlot, :errors)).to be_blank
      expect(own_slot.reload.load).to eq(second_load)

      removed = client_operation("DeleteSlot", variables: { id: own_slot.id }, as: manifest_user)
      expect(removed.dig(:data, :deleteSlot, :errors)).to be_blank

      expect(manifest(other_member, as: manifest_user).dig(:data, :createSlot, :slot, :id)).to be_present
      expect(manifest(manifest_staff, as: manifest_user).dig(:data, :createSlot, :slot, :id)).to be_present
    end

    it "omits the self-service slot permissions of a member and keeps the staff ones" do
      expect(permissions_of(fun_jumper)).not_to include("createSlot", "updateSlot", "deleteSlot")
      expect(fun_jumper.permission_names).not_to include("createSlot", "updateSlot", "deleteSlot")
      expect(permissions_of(manifest_staff)).to include("createSlot", "createUserSlot", "updateSlot", "updateUserSlot", "deleteSlot")
      expect(fun_jumper.can?(:createSlot)).to be(false)
      expect(manifest_staff.can?(:createSlot)).to be(true)
    end

    it "changes nothing when the setting is on again" do
      dropzone.update!(settings: { allow_self_manifest: true })

      expect(fun_jumper.reload.permission_names).to include("createSlot", "updateSlot", "deleteSlot")
      expect(manifest(student, as: student_user).dig(:data, :createSlot, :slot, :id)).to be_present
    end
  end
end
