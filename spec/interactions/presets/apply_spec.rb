# frozen_string_literal: true

require "rails_helper"

RSpec.describe Presets::Apply do
  let(:owner) { create(:user) }

  def create_operator(industry, **attrs)
    Setup::Operators::CreateOperator.run!(owner: owner, industry: industry, name: "Test #{industry}", time_zone: "Australia/Brisbane", **attrs)
  end

  describe "a skydiving operator" do
    let(:parity) { YAML.safe_load_file(Rails.root.join("spec/fixtures/industries/skydiving_parity.yml")) }
    let(:operator) { create_operator("skydiving", certification_body_ids: [CertificationBody.first.id]) }

    it "has the roles it had before industry templates" do
      expect(operator.user_roles.pluck(:name)).to match_array(parity["roles"].keys)
    end

    it "has the role permissions it had before industry templates" do
      parity["roles"].each do |role, permissions|
        actual = operator.user_roles.find_by!(name: role).permissions.pluck(:name).sort
        expect(actual).to eq(permissions), "role #{role} differs"
      end
    end

    it "has the default roles it had before industry templates" do
      expect(operator.user_roles.default.name).to eq(parity["default_role"])
      expect(operator.user_roles.default_licensed.name).to eq(parity["default_certified_role"])
    end

    it "has the settings it had before industry templates" do
      expect(operator.settings).to include(parity["settings"])
    end

    it "makes the creator the owner" do
      expect(operator.memberships.owner.map(&:user)).to eq([owner])
    end

    it "keeps its industry" do
      operator.industry = "generic"

      expect(operator).not_to be_valid
      expect(operator.errors[:industry]).to be_present
    end
  end

  describe "applying twice" do
    it "adds nothing the second time" do
      operator = create_operator("skydiving", certification_body_ids: [CertificationBody.first.id])

      expect { described_class.run!(operator: operator) }.
        not_to(change { [operator.user_roles.count, UserRolePermission.count, operator.ticket_types.count, OperatorActivityType.count] })
    end

    it "leaves the changes an operator made to its roles" do
      operator = create_operator("skydiving", certification_body_ids: [CertificationBody.first.id])
      role = operator.user_roles.find_by!(name: "student")
      role.user_role_permissions.destroy_all

      described_class.run!(operator: operator)

      expect(role.reload.permissions.pluck(:name)).to match_array(%w(readLoad createSlot))
    end
  end

  describe "a generic operator" do
    let(:operator) { create_operator("generic") }

    it "gets the roles of its template" do
      expect(operator.user_roles.pluck(:name)).to match_array(%w(customer front_desk admin owner))
      expect(operator.user_roles.default.name).to eq("customer")
      expect(operator.user_roles.default_licensed.name).to eq("customer")
    end

    it "starts with no requirements" do
      expect(operator.settings).to include("require_certification" => false, "require_credits" => false, "require_equipment" => false)
    end

    it "can create a vehicle, a load and a slot" do
      vehicle = operator.vehicles.create!(name: "Boat 1", capacity: 6, kind: "vehicle")
      captain = operator.memberships.owner.first
      load = Load.create!(operator: operator, vehicle: vehicle, max_slots: 6, state: "open", is_open: true)
      guest = create(:membership, operator: operator, user_role: operator.user_roles.default)
      ticket = create(:ticket_type, operator: operator)

      slot = Slot.create!(load: load, membership: guest, ticket_type: ticket, created_by: captain, group_number: 0, is_paid: false)

      expect(load.reload.slots).to eq([slot])
    end
  end
end
