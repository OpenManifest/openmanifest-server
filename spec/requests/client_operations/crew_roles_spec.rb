# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Client operations: crew roles" do
  include_context "operator"

  let(:owner_user) { create(:user) }
  let!(:owner) { create(:membership, operator: operator, user: owner_user, user_role: operator.user_roles.find_by(name: "owner")) }

  describe "CrewRoles" do
    it "lists the roles with what the load form needs" do
      json = client_operation("CrewRoles", variables: { operatorId: operator.id }, as: user)

      roles = json.dig(:data, :operator, :crewRoles)
      expect(roles.pluck(:key)).to eq(%w(pilot gca load_master))
      expect(roles.first).to include(name: "Pilot", scope: "vehicle", required: true, permission: "actAsPilot", occupiesSlot: false, vehicleKinds: [])
    end

    it "requires authentication" do
      json = client_operation("CrewRoles", variables: { operatorId: operator.id })

      expect(json.dig(:errors, 0, :extensions, :code)).to eq("AUTHENTICATION_ERROR")
    end
  end

  describe "CreateCrewRole" do
    it "adds a role with the key the setup list makes from its name" do
      attributes = { operatorId: operator.id, key: "camera_flyer", name: "Camera flyer", scope: "load", required: false, occupiesSlot: true, permission: nil, position: 3 }
      json = client_operation("CreateCrewRole", variables: { attributes: attributes }, as: owner_user)

      expect(json.dig(:data, :createCrewRole, :errors)).to be_nil
      expect(json.dig(:data, :createCrewRole, :crewRole)).to include(key: "camera_flyer", name: "Camera flyer", occupiesSlot: true, permission: nil)
      expect(operator.crew_roles.kept.pluck(:key)).to include("camera_flyer")
    end

    it "names the field of a key the operator already has" do
      json = client_operation("CreateCrewRole", variables: { attributes: { operatorId: operator.id, key: "pilot", name: "Pilot", scope: "vehicle" } }, as: owner_user)

      expect(json.dig(:data, :createCrewRole, :crewRole)).to be_nil
      expect(json.dig(:data, :createCrewRole, :fieldErrors).pluck(:field)).to include("key")
    end

    it "refuses a member who may not change the operator" do
      json = client_operation("CreateCrewRole", variables: { attributes: { operatorId: operator.id, key: "camera", name: "Camera" } }, as: user)

      expect(json.dig(:data, :createCrewRole, :crewRole)).to be_nil
      expect(operator.crew_roles.kept.pluck(:key)).not_to include("camera")
    end
  end

  describe "UpdateCrewRole" do
    it "makes a role required and changes who may fill it" do
      gca = operator.crew_roles.find_by!(key: "gca")
      json = client_operation("UpdateCrewRole", variables: { id: gca.id, attributes: { name: "Ground control", required: false, permission: "actAsLoadMaster" } }, as: owner_user)

      expect(json.dig(:data, :updateCrewRole, :crewRole)).to include(name: "Ground control", required: false, permission: "actAsLoadMaster")
      expect(gca.reload.key).to eq("gca")
    end
  end

  describe "ArchiveCrewRole" do
    it "archives a role, which the list then leaves out" do
      load_master = operator.crew_roles.find_by!(key: "load_master")
      json = client_operation("ArchiveCrewRole", variables: { id: load_master.id }, as: owner_user)

      expect(json.dig(:data, :archiveCrewRole, :crewRole, :key)).to eq("load_master")
      roles = client_operation("CrewRoles", variables: { operatorId: operator.id }, as: user).dig(:data, :operator, :crewRoles)
      expect(roles.pluck(:key)).to eq(%w(pilot gca))
    end
  end
end
