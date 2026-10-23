# frozen_string_literal: true

require "rails_helper"

# The documents behind People (U5.1) and the member profile (U5.2)
RSpec.describe "Client operations: People and the member profile" do
  include_context "operator"
  include_context "certification_body_sync"

  let(:owner_user) { create(:user) }
  let!(:owner) { create(:membership, operator: operator, user: owner_user, user_role: operator.user_roles.find_by(name: "owner"), credits: 500) }
  let!(:pilot) { create(:membership, operator: operator).tap { |member| member.grant!(:actAsPilot) } }
  let!(:ticket_type) { create(:ticket_type, operator: operator, name: "Height", cost: 40) }
  let(:activity) { ActivityType.allowed_for([fun_jumper]).first }

  before do
    operator.update!(settings: operator.settings.merge("require_equipment_inspection" => false, "require_equipment_in_service" => false))
    fun_jumper.update!(credits: 300)
  end

  # A load the member flew: it left and landed
  def flown_load!(member: fun_jumper, at: 1.hour.ago)
    load = create(:load, vehicle: vehicle, pilot: pilot, gca: owner, load_master: owner, max_slots: 10)
    slot = create(:slot, load: load, membership: member, operator: operator, ticket_type: ticket_type, activity_type: activity)
    slot.update_columns(created_at: at)
    load.update_columns(state: Load.states[:completed], departed_at: at, completed_at: at + 10.minutes)
    [load, slot]
  end

  describe "People" do
    def people(as: owner_user, **variables)
      client_operation("People", variables: { operatorId: operator.id, first: 50 }.merge(variables), as: as)
    end

    it "lists every member, with a licence or not, with role, credit, readiness and last slot" do
      unlicensed = create(:membership, operator: operator).tap { |member| member.update!(certification_level: nil) }
      load, = flown_load!

      json = people

      expect(json[:errors]).to be_nil
      nodes = json.dig(:data, :memberships, :edges).pluck(:node)
      expect(nodes.pluck(:id)).to include(fun_jumper.id.to_s, unlicensed.id.to_s, owner.id.to_s)
      jumper = nodes.find { |node| node[:id] == fun_jumper.id.to_s }
      expect(jumper).to include(:creditsCents, :role, :certificationLevel)
      expect(jumper.dig(:eligibility, :rules)).to all(include(:code, :ok, :status))
      expect(jumper.dig(:lastSlot, :load, :id)).to eq(load.id.to_s)
    end

    it "searches by name and pages" do
      user.update!(name: "Zed Uniquename")

      found = people(search: "Uniquename").dig(:data, :memberships, :edges)
      page = people(first: 1).dig(:data, :memberships)

      expect(found.map { |edge| edge.dig(:node, :id) }).to eq([fun_jumper.id.to_s])
      expect(page[:edges].size).to eq(1)
      expect(page.dig(:pageInfo, :hasNextPage)).to be(true)
    end
  end

  describe "Profile" do
    def profile(id = fun_jumper.id, as: user, **variables)
      client_operation("Profile", variables: { id: id, slots: 20 }.merge(variables), as: as)
    end

    it "gives a member their own profile: readiness, certifications, equipment with its inspection and loads" do
      rig = create(:equipment, user: user)
      create(:equipment_inspection, equipment: rig, membership: fun_jumper, inspected_by: owner)
      certification = UserCertification.find_by!(user: user)
      qualification = Qualification.create!(certification_body: certification.certification_body, name: "Camera", slug: "camera")
      create(:user_qualification, user_certification: certification, qualification: qualification, number: "C-7", expires_at: 1.year.from_now)
      _, slot = flown_load!

      json = profile

      expect(json[:errors]).to be_nil
      membership = json.dig(:data, :membership)
      expect(membership[:id]).to eq(fun_jumper.id.to_s)
      expect(membership[:permissions]).to include("createSlot")
      expect(membership.dig(:eligibility, :rules)).to all(include(:code, :ok, :status))
      expect(membership.dig(:userCertification, :id)).to eq(certification.id.to_s)
      held = membership.dig(:user, :userCertifications).find { |item| item[:id] == certification.id.to_s }
      expect(held[:qualifications]).to contain_exactly(include(name: "Camera", number: "C-7", current: true))
      expect(membership.dig(:user, :equipment).pluck(:id)).to eq([rig.id.to_s])
      expect(membership[:equipmentInspections]).to contain_exactly(include(isOk: true, equipment: include(id: rig.id.to_s)))
      node = membership.dig(:slots, :edges, 0, :node)
      expect(node).to include(id: slot.id.to_s, costCents: 4000)
      expect(node[:load]).to include(state: "completed", loadNumber: slot.load.load_number)
      expect(node.dig(:ticketType, :name)).to eq("Height")
    end

    it "lists the loads newest first, as many as asked for" do
      _, older = flown_load!(at: 2.days.ago)
      _, newer = flown_load!(at: 1.hour.ago)

      first = profile(slots: 1).dig(:data, :membership, :slots)
      all = profile.dig(:data, :membership, :slots)

      expect(first[:edges].map { |edge| edge.dig(:node, :id) }).to eq([newer.id.to_s])
      expect(first.dig(:pageInfo, :hasNextPage)).to be(true)
      expect(all[:edges].map { |edge| edge.dig(:node, :id) }).to eq([newer.id.to_s, older.id.to_s])
      expect(all.dig(:pageInfo, :hasNextPage)).to be(false)
    end

    it "says what stops the member" do
      fun_jumper.update!(credits: 0)
      operator.update!(settings: operator.settings.merge("require_credits" => true, "allow_negative_credits" => false))

      eligibility = profile.dig(:data, :membership, :eligibility)

      expect(eligibility[:ready]).to be(false)
      expect(eligibility[:rules].find { |rule| rule[:code] == "credits" }).to include(ok: false, status: "FAIL")
    end

    it "gives a student their own profile without the right to read people, and nobody else's" do
      student = create(:membership, operator: operator, user_role: operator.user_roles.find_by(name: "student"))

      own = profile(student.id, as: student.user)
      other = profile(fun_jumper.id, as: student.user)

      expect(own[:errors]).to be_nil
      expect(own.dig(:data, :membership, :id)).to eq(student.id.to_s)
      expect(other.dig(:errors, 0, :extensions, :code)).to eq("FORBIDDEN")
      expect(other.dig(:data, :membership)).to be_nil
    end

    it "gives staff a member's profile with their permissions" do
      json = profile(fun_jumper.id, as: owner_user)

      expect(json[:errors]).to be_nil
      expect(json.dig(:data, :membership, :id)).to eq(fun_jumper.id.to_s)
      expect(json.dig(:data, :membership, :permissions)).to include("createSlot")
    end
  end
end
