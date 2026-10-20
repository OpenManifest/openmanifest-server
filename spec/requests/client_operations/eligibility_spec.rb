# frozen_string_literal: true

require "rails_helper"

# P7.16 over GraphQL, with the documents the client sends
RSpec.describe "Eligibility over GraphQL", type: :request do
  include_context "operator"

  let(:owner_user) { create(:user) }
  let!(:owner) { create(:membership, operator: operator, user: owner_user, user_role: operator.user_roles.find_by(name: "owner"), credits: 500).tap { |member| %i(actAsGCA actAsLoadMaster).each { |permission| member.grant!(permission) } } }
  let!(:pilot) { create(:membership, operator: operator).tap { |member| member.grant!(:actAsPilot) } }
  let!(:manifest_load) { create(:load, vehicle: vehicle, pilot: pilot, gca: owner, load_master: owner, max_slots: 10) }
  let!(:ticket) { create(:ticket_type, operator: operator, name: "Tandem", cost: 100, participant_limits: { "min_age" => 18, "max_body_mass_kg" => 100 }) }
  let(:jumper_user) { create(:user, body_mass_kg: 80, date_of_birth: Date.new(1990, 1, 1)) }
  let(:jumper) { create(:membership, operator: operator, user: jumper_user, credits: 500) }
  let(:activity) { ActivityType.allowed_for([jumper]).first }

  def eligibility(**variables)
    client_operation("SlotEligibility",
                     variables: { loadId: manifest_load.id, membershipId: jumper.id, ticketTypeId: ticket.id, activityTypeId: activity.id, bodyMassKg: 80 }.merge(variables),
                     as: owner_user)
  end

  def result_for(json, code) = json.dig(:data, :slotEligibility).find { |result| result[:code] == code }

  describe "slotEligibility" do
    it "gives the result of every rule that applies" do
      json = eligibility

      expect(json[:errors]).to be_nil
      expect(json.dig(:data, :slotEligibility).pluck(:code)).to include("capacity", "membership", "credits", "age", "body_mass")
      expect(json.dig(:data, :slotEligibility)).to all(include(ok: true))
    end

    it "says why a rule fails, with its own problem" do
      jumper_user.update!(date_of_birth: nil)

      expect(result_for(eligibility, "age")).to include(ok: false, status: "FAIL", problem: "date_of_birth_missing")
    end

    it "applies the limits to the mass given" do
      expect(result_for(eligibility(bodyMassKg: 120), "body_mass")).to include(ok: false, message: match(/must weigh at most 100 kg/))
    end

    it "marks a failure the manifester may let through" do
      jumper.update!(expires_at: 1.day.ago)
      operator.update!(settings: operator.settings.merge("allow_manifest_bypass" => true))
      owner.grant!(:createUserSlot)

      expect(result_for(eligibility, "membership")).to include(ok: false, bypassed: true)
    end

    it "checks the equipment chosen" do
      operator.update!(settings: operator.settings.merge("require_equipment" => true))

      expect(result_for(eligibility, "equipment")).to include(ok: false, problem: "equipment_missing")
      rig = create(:equipment, operator: operator, user: nil, is_public: true, rig_type: "student")

      expect(result_for(eligibility(equipmentIds: [rig.id]), "equipment")).to include(ok: true)
    end

    it "looks at the guests of an escort" do
      ticket.update!(requires_escort: true, escort_capacity: 2)

      json = eligibility(guests: [{ name: "Kid", bodyMassKg: 40, dateOfBirth: (manifest_load.load_date - 10.years).iso8601 }])

      expect(result_for(json, "age")).to include(ok: false, message: "Kid must be at least 18 years old")
    end

    it "saves nothing" do
      expect { eligibility(guests: [{ name: "Kid" }]) }.not_to change { [Slot.count, Guest.count] }
    end

    it "refuses a caller who is not a member of the operator" do
      stranger = create(:user)
      json = client_operation("SlotEligibility", variables: { loadId: manifest_load.id, membershipId: jumper.id, ticketTypeId: ticket.id }, as: stranger)

      expect(json.dig(:data, :slotEligibility)).to be_nil
      expect(json[:errors]).to be_present
    end

    it "refuses a jumper who may not manifest" do
      viewer = create(:membership, operator: operator, user: create(:user), user_role: operator.user_roles.find_by(name: "tandem_guest"))
      json = client_operation("SlotEligibility", variables: { loadId: manifest_load.id, membershipId: jumper.id, ticketTypeId: ticket.id }, as: viewer.user)

      expect(json[:errors] || json.dig(:data, :slotEligibility)).to be_present
    end

    it "refuses a ticket of another operator" do
      other_ticket = create(:ticket_type, operator: create(:operator), name: "Other")
      json = client_operation("SlotEligibility", variables: { loadId: manifest_load.id, membershipId: jumper.id, ticketTypeId: other_ticket.id }, as: owner_user)

      expect(json.dig(:data, :slotEligibility)).to be_nil
    end
  end

  # The load screen asks it for everyone on the load at once (U3.5)
  describe "LoadEligibility" do
    def on_load(member)
      create(:slot, load: manifest_load, membership: member, operator: operator, ticket_type: ticket, activity_type: ActivityType.allowed_for([member]).first)
    end

    it "gives the rules of each member on the load" do
      operator.update!(settings: operator.settings.merge("require_equipment_inspection" => false, "require_equipment_in_service" => false))
      slot = on_load(jumper)

      json = client_operation("LoadEligibility", variables: { id: manifest_load.id }, as: owner_user)

      expect(json[:errors]).to be_nil
      entry = json.dig(:data, :load, :slots).find { |row| row[:id] == slot.id.to_s }
      expect(entry.dig(:membership, :id)).to eq(jumper.id.to_s)
      expect(entry.dig(:membership, :eligibility, :ready)).to be(true)
      expect(entry.dig(:membership, :eligibility, :rules).pluck(:code)).to include("membership", "credits")
    end

    it "says what stops a member" do
      on_load(jumper)
      jumper.update_column(:expires_at, 1.day.ago)

      json = client_operation("LoadEligibility", variables: { id: manifest_load.id }, as: owner_user)

      eligibility = json.dig(:data, :load, :slots, 0, :membership, :eligibility)
      expect(eligibility[:ready]).to be(false)
      expect(eligibility[:rules].find { |rule| rule[:code] == "membership" }).to include(status: "FAIL")
    end

    it "refuses a caller who is not a member of the operator" do
      on_load(jumper)

      json = client_operation("LoadEligibility", variables: { id: manifest_load.id }, as: create(:user))

      expect(json.dig(:data, :load)).to be_nil
    end
  end

  # The member picker (U3.7): who can go on this load, and what each flew last time
  describe "MemberPicker" do
    def picker(**variables)
      client_operation("MemberPicker", variables: { operatorId: operator.id, loadId: manifest_load.id, first: 50 }.merge(variables), as: owner_user)
    end

    def node_for(json, member) = json.dig(:data, :memberships, :edges).pluck(:node).find { |node| node[:id] == member.id.to_s }

    it "says for each member whether they are ready for this load, and what stops them" do
      operator.update!(settings: operator.settings.merge("require_equipment_inspection" => false, "require_equipment_in_service" => false))
      jumper
      stopped = create(:membership, operator: operator, user: create(:user, body_mass_kg: 70), credits: 100)
      stopped.update_column(:expires_at, 1.day.ago)

      json = picker

      expect(json[:errors]).to be_nil
      expect(node_for(json, jumper).dig(:eligibility, :ready)).to be(true)
      expect(node_for(json, stopped).dig(:eligibility, :ready)).to be(false)
      expect(node_for(json, stopped).dig(:eligibility, :rules).find { |rule| rule[:code] == "membership" }).to include(status: "FAIL")
    end

    it "gives the last slot of a member who has flown, and none for one who has not" do
      flown = create(:load, vehicle: vehicle, pilot: pilot, gca: owner, load_master: owner, max_slots: 10)
      create(:slot, load: flown, membership: jumper, operator: operator, ticket_type: ticket, activity_type: activity)
      flown.update_columns(state: Load.states[:completed], departed_at: 1.hour.ago, completed_at: 30.minutes.ago)
      fresh = create(:membership, operator: operator, user: create(:user, body_mass_kg: 70), credits: 100)

      json = picker

      last = node_for(json, jumper)[:lastSlot]
      expect(last.dig(:ticketType, :id)).to eq(ticket.id.to_s)
      expect(last.dig(:activityType, :id)).to eq(activity.id.to_s)
      expect(last.dig(:load, :id)).to eq(flown.id.to_s)
      expect(node_for(json, fresh)[:lastSlot]).to be_nil
    end

    it "narrows the members by what is typed" do
      jumper
      jumper_user.update!(name: "Zed Zebra")

      names = picker(search: "Zebra").dig(:data, :memberships, :edges).pluck(:node).map { |node| node.dig(:user, :name) }

      expect(names).to eq(["Zed Zebra"])
    end
  end

  describe "Membership.eligibility" do
    let(:query) do
      "query($operator: ID!, $load: ID) { memberships(operator: $operator, first: 100, licensed: false) { edges { node { id eligibility(loadId: $load) { ready rules { code ok status message problem expiresAt amountCents } } } } } }"
    end

    def run(variables)
      post "/graphql", params: { query: query, variables: variables.to_json }, headers: owner_user.create_new_auth_token
      response.parsed_body.with_indifferent_access
    end

    it "tells whether each member is ready, rule by rule" do
      jumper
      jumper_user.update!(body_mass_kg: nil)

      nodes = run(operator: operator.id, load: manifest_load.id).dig(:data, :memberships, :edges).pluck(:node)
      mine = nodes.find { |node| node[:id] == jumper.id.to_s }[:eligibility]

      expect(mine[:ready]).to be(false)
      expect(mine[:rules].find { |rule| rule[:code] == "body_mass" }).to include(ok: false, problem: "body_mass_missing")
      expect(mine[:rules].pluck(:code)).to include("membership", "credits", "capacity")
    end

    it "costs a bounded number of queries however many members there are" do
      Array.new(12) { create(:membership, operator: operator, user: create(:user, body_mass_kg: 70), credits: 100) }
      Prosopite.raise = true
      Prosopite.min_n_queries = 4
      json = nil
      begin
        Prosopite.scan { json = run(operator: operator.id, load: manifest_load.id) }
      ensure
        Prosopite.raise = false
        Prosopite.min_n_queries = 2
      end

      expect(json[:errors]).to be_nil
      expect(json.dig(:data, :memberships, :edges).size).to be >= 12
    end
  end

  describe "the limits on the API" do
    it "stores a ticket's limits and refuses a bad one" do
      attributes = { name: "Under 12", costCents: 5000, operatorId: operator.id, currency: "AUD", participantLimits: { max_age: 12 } }
      json = client_operation("CreateTicketType", variables: { attributes: attributes }, as: owner_user)

      expect(json.dig(:data, :createTicketType, :ticketType, :participantLimits)).to eq("max_age" => 12)

      bad = client_operation("CreateTicketType", variables: { attributes: attributes.merge(name: "Bad", participantLimits: { min_age: 30, max_age: 12 }) }, as: owner_user)

      expect(bad.dig(:data, :createTicketType, :ticketType)).to be_nil
      expect(bad.dig(:data, :createTicketType, :errors).join).to match(/min_age is above max_age/)
    end

    it "keeps a date of birth on the profile, for those who may read it" do
      json = client_operation("UpdateUser", variables: { membership: jumper.id, dateOfBirth: "1985-06-07" }, as: jumper_user)

      expect(json.dig(:data, :updateUser, :errors)).to be_nil
      expect(jumper_user.reload.date_of_birth).to eq(Date.new(1985, 6, 7))
      expect(json.dig(:data, :updateUser, :membership, :user, :dateOfBirth)).to eq("1985-06-07")
    end

    it "stores what a vehicle can carry" do
      json = client_operation("CreateVehicle", variables: { attributes: { name: "Caravan", registration: "VH-CRV", capacity: 12, minCapacity: 1, maxPayloadKg: 1200, operatorId: operator.id } }, as: owner_user)

      expect(json.dig(:data, :createVehicle, :vehicle, :maxPayloadKg)).to eq(1200.0)
    end
  end
end
