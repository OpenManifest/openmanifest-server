# frozen_string_literal: true

require "rails_helper"

# Every example here states an access the API must refuse across dropzones ("tenants").
# They are pending today (BUG-001..BUG-013) and become the acceptance tests of the Phase 6 security tasks.
# The actor is a regular member (or the owner) of dropzone A; dropzone B belongs to someone else.
RSpec.describe "Tenant isolation" do
  let(:dropzone_a) { create(:dropzone, credits: 50, state: "public") }
  let(:dropzone_b) { create(:dropzone, credits: 50, state: "public") }
  let(:plane_a) { create(:plane, dropzone: dropzone_a, max_slots: 16) }
  let(:plane_b) { create(:plane, dropzone: dropzone_b, max_slots: 16) }

  let(:member_user) { create(:user) }
  let!(:member_a) { create(:dropzone_user, dropzone: dropzone_a, user: member_user, user_role: dropzone_a.user_roles.find_by(name: "fun_jumper"), credits: 300) }
  let(:owner_user) { create(:user) }
  let!(:owner_a) { create(:dropzone_user, dropzone: dropzone_a, user: owner_user, user_role: dropzone_a.user_roles.find_by(name: "owner"), credits: 500) }

  let(:owner_b_user) { create(:user) }
  let!(:owner_b) { create(:dropzone_user, dropzone: dropzone_b, user: owner_b_user, user_role: dropzone_b.user_roles.find_by(name: "owner"), credits: 500) }
  let!(:member_b) { create(:dropzone_user, dropzone: dropzone_b, user_role: dropzone_b.user_roles.find_by(name: "fun_jumper"), credits: 300) }
  let!(:load_a) { create(:load, plane: plane_a, pilot: owner_a, gca: owner_a, load_master: owner_a) }
  let!(:load_b) { create(:load, plane: plane_b, pilot: owner_b, gca: owner_b, load_master: owner_b) }
  let!(:ticket_a) { create(:ticket_type, dropzone: dropzone_a, name: "Height", cost: 40) }
  let!(:ticket_b) { create(:ticket_type, dropzone: dropzone_b, name: "Height", cost: 40) }

  def graphql(query, as:, variables: {})
    post "/graphql", params: { query: query, variables: variables.to_json }, headers: as.create_new_auth_token
    JSON.parse(response.body).with_indifferent_access
  end

  def refused?(json, *path)
    json[:errors].present? || json.dig(:data, *path).blank?
  end

  def manifest_b_member_on_load_b
    json = client_operation("ManifestUser",
                            variables: {
                              load: load_b.id, dropzoneUser: member_b.id, ticketType: ticket_b.id,
                              jumpType: JumpType.allowed_for([member_b]).first.id, exitWeight: 80,
                            },
                            as: owner_b_user)
    Slot.find(json.dig(:data, :createSlot, :slot, :id))
  end

  describe "BUG-001: the access context is per request" do
    it "is not shared between callers" do
      expect(AccessContext::CurrentUser.for(member_user)).not_to equal(AccessContext::CurrentUser.for(owner_user))
    end
  end

  describe "BUG-002: reading another dropzone's data" do
    it "refuses load(id:) of a load in B" do
      expect(refused?(client_operation("Load", variables: { id: load_b.id }, as: member_user), :load)).to be(true)
    end

    it "refuses loads(dropzone:) for B" do
      expect(client_operation("Loads", variables: { dropzone: dropzone_b.id }, as: member_user).dig(:data, :loads, :edges).to_a).to be_empty
    end

    it "refuses dropzoneUser(id:) of a member of B" do
      expect(refused?(client_operation("DropzoneUser", variables: { id: member_b.id }, as: member_user), :dropzoneUser)).to be(true)
    end

    it "refuses dropzoneUsers(dropzone:) for B" do
      expect(client_operation("DropzoneUsers", variables: { dropzoneId: dropzone_b.id }, as: member_user).dig(:data, :dropzoneUsers, :edges).to_a).to be_empty
    end

    it "refuses planes(dropzone:) for B" do
      plane_b
      expect(client_operation("Planes", variables: { dropzoneId: dropzone_b.id }, as: member_user).dig(:data, :planes).to_a).to be_empty
    end

    it "refuses ticketTypes(dropzone:) for B" do
      expect(client_operation("TicketTypes", variables: { dropzone: dropzone_b.id }, as: member_user).dig(:data, :ticketTypes).to_a).to be_empty
    end

    it "refuses extras(dropzone:) for B" do
      Extra.create!(dropzone: dropzone_b, name: "Video", cost: 5)
      expect(client_operation("TicketTypeExtras", variables: { dropzoneId: dropzone_b.id }, as: member_user).dig(:data, :extras).to_a).to be_empty
    end

    it "refuses masterLog(dropzone:) for B" do
      json = client_operation("MasterLog", variables: { dropzoneId: dropzone_b.id, date: Date.current.iso8601 }, as: member_user)
      expect(refused?(json, :masterLog)).to be(true)
    end

    it "refuses availableRigs(dropzoneUser:) for a member of B" do
      rig = create(:rig, user: member_b.user, dropzone: nil)
      create(:rig_inspection, rig: rig, dropzone_user: member_b, inspected_by: owner_b, is_ok: true)
      expect(client_operation("AvailableRigs", variables: { dropzoneUserId: member_b.id }, as: member_user).dig(:data, :availableRigs).to_a).to be_empty
    end
  end

  describe "BUG-003: activity" do
    it "returns no events of B when no dropzone filter is given" do
      Activity::CreateEvent.run!(access_context: ApplicationInteraction::AccessContext.new(owner_b), level: :info, access_level: :user,
                                 message: "event in dropzone B", resource: dropzone_b, action: :created, created_by: owner_b, dropzone: dropzone_b)
      messages = client_operation("Activity", variables: {}, as: member_user).dig(:data, :activity, :edges).map { |e| e.dig(:node, :message) }
      expect(messages).not_to include("event in dropzone B")
    end
  end

  describe "BUG-004: images" do
    it "has no image(id:) query any more" do
      blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("secret master log"), filename: "log.json", content_type: "application/json")
      json = graphql("query($id: Int!) { image(id: $id) }", variables: { id: blob.id }, as: member_user)
      expect(json[:data]).to be_nil
      expect(json.dig(:errors, 0, :message)).to include("image")
    end
  end

  describe "BUG-005: authorization checks must not write" do
    it "does not create a membership in B when A's owner updates B's plane" do
      expect { client_operation("UpdateAircraft", variables: { id: plane_b.id, attributes: { name: "Hijacked" } }, as: owner_user) }.
        not_to(change { dropzone_b.dropzone_users.where(user: owner_user).count })
    end
  end

  describe "BUG-006: manifesting other people" do
    it "refuses a student manifesting another member" do
      student_user = create(:user)
      create(:dropzone_user, dropzone: dropzone_a, user: student_user, user_role: dropzone_a.user_roles.find_by(name: "student"), credits: 100)
      json = client_operation("ManifestUser",
                              variables: {
                                load: load_a.id, dropzoneUser: member_a.id, ticketType: ticket_a.id,
                                jumpType: JumpType.allowed_for([member_a]).first.id, exitWeight: 80,
                              },
                              as: student_user)
      expect(refused?(json, :createSlot, :slot)).to be(true)
    end
  end

  describe "BUG-007: moving slots between dropzones" do
    it "refuses a student of B moving another member's slot onto a load of A" do
      slot = manifest_b_member_on_load_b
      student_user = create(:user)
      create(:dropzone_user, dropzone: dropzone_b, user: student_user, user_role: dropzone_b.user_roles.find_by(name: "student"))
      client_operation("MoveSlot", variables: { sourceSlot: slot.id, targetLoad: load_a.id }, as: student_user)
      expect(slot.reload.load).to eq(load_b)
    end
  end

  describe "BUG-008: orders against another dropzone" do
    it "refuses an order that pays a member of B" do
      json = client_operation("CreateOrder",
                              variables: { buyer: member_a.to_gid_param, seller: member_b.to_gid_param, dropzone: dropzone_a.id, title: "x", amount: 100 },
                              as: member_user)
      expect(refused?(json, :createOrder, :order)).to be(true)
    end
  end

  describe "BUG-009: client-supplied dropzone for authorization" do
    it "refuses updating B's form template with dropzoneId set to A" do
      pending "BUG-009"
      template = create(:form_template, dropzone: dropzone_b, definition: "original")
      dropzone_b.update!(rig_inspection_template: template)
      client_operation("UpdateRigInspectionTemplate", variables: { dropzoneId: dropzone_a.id, formId: template.id, definition: "hijacked" }, as: owner_user)
      expect(template.reload.definition).to eq("original")
    end
  end

  describe "BUG-010: moving records between tenants" do
    it "refuses B's owner moving a ticket type of B into A by sending dropzoneId" do
      pending "BUG-010"
      client_operation("UpdateTicketType", variables: { id: ticket_b.id, attributes: { dropzoneId: dropzone_a.id, cost: 1.0 } }, as: owner_b_user)
      expect(ticket_b.reload.dropzone).to eq(dropzone_b)
    end
  end

  describe "BUG-011: subscriptions" do
    it "refuses subscribing to loadUpdated for a load of B" do
      pending "BUG-011"
      channel = Struct.new(:params) { def stream_from(*); end }.new({ "channelId" => "tenant-spec" })
      query = "subscription($id: ID!) { loadUpdated(loadId: $id) { load { id } } }"
      result = DzSchema.execute(query: query, variables: { "id" => load_b.id.to_s },
                                context: { channel: channel, current_resource: member_user, access_context: AccessContext::CurrentUser.for(member_user) })
      expect(result.to_h.dig("data", "loadUpdated", "load")).to be_nil
    end
  end

  describe "BUG-013: personal data of members of other dropzones" do
    it "hides email, phone and pushToken of a member of B" do
      member_b.user.update!(push_token: "ExponentPushToken[secret]")
      json = graphql("query($id: ID!) { dropzoneUser(id: $id) { user { email phone pushToken } } }", variables: { id: member_b.id }, as: member_user)
      user_data = json.dig(:data, :dropzoneUser, :user)
      expect(user_data.to_h.values.compact).to be_empty
    end
  end
end
