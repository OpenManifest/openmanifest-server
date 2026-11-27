# frozen_string_literal: true

require "rails_helper"

# P7.10 through the API: crew roles, and the crew of a load
RSpec.describe "Crew roles" do
  include_context "operator"

  let(:owner_user) { create(:user) }
  let!(:owner) { create(:membership, operator: operator, user: owner_user, user_role: operator.user_roles.find_by(name: "owner"), credits: 500).tap { |member| %i(actAsGCA actAsLoadMaster).each { |permission| member.grant!(permission) } } }
  let!(:pilot) { create(:membership, operator: operator).tap { |member| member.grant!(:actAsPilot) } }
  let(:roles) { operator.crew_roles.index_by(&:key) }

  def graphql(query, variables = {}, as: owner_user)
    post "/graphql", params: { query: query, variables: variables.to_json }, headers: as.create_new_auth_token
    response.parsed_body.with_indifferent_access
  end

  describe "operator.crewRoles" do
    it "lists the roles in order, for any member" do
      json = graphql("query($id: ID!) { operator(id: $id) { crewRoles { key name scope required occupiesSlot permission vehicleKinds } } }", { id: operator.id }, as: user)

      expect(json.dig(:data, :operator, :crewRoles).pluck(:key)).to eq(%w(pilot gca load_master))
      expect(json.dig(:data, :operator, :crewRoles, 0)).to include(scope: "vehicle", required: true, permission: "actAsPilot", vehicleKinds: [])
    end
  end

  describe "createCrewRole, updateCrewRole, archiveCrewRole" do
    let(:create_role) { "mutation($attributes: CrewRoleInput!) { createCrewRole(input: { attributes: $attributes }) { errors fieldErrors { field } crewRole { id key name scope occupiesSlot } } }" }
    let(:update_role) { "mutation($id: Int!, $attributes: CrewRoleInput!) { updateCrewRole(input: { id: $id, attributes: $attributes }) { errors crewRole { name required } } }" }
    let(:archive_role) { "mutation($id: Int!) { archiveCrewRole(input: { id: $id }) { errors crewRole { id discardedAt } } }" }

    it "creates a role for the operator" do
      json = nil
      expect do
        json = graphql(create_role, { attributes: { operatorId: operator.id, key: "spotter", name: "Spotter", scope: "vehicle", occupiesSlot: true } })
      end.to change(CrewRole, :count).by(1)

      expect(json.dig(:data, :createCrewRole, :crewRole)).to include(key: "spotter", name: "Spotter", scope: "vehicle", occupiesSlot: true)
    end

    it "refuses a key that is taken" do
      json = graphql(create_role, { attributes: { operatorId: operator.id, key: "gca", name: "Second GCA" } })

      expect(json.dig(:data, :createCrewRole, :crewRole)).to be_nil
      expect(json.dig(:data, :createCrewRole, :fieldErrors, 0, :field)).to eq("key")
    end

    it "changes and archives a role" do
      role = roles.fetch("load_master")

      json = graphql(update_role, { id: role.id, attributes: { name: "Load boss", required: true } })
      expect(json.dig(:data, :updateCrewRole, :crewRole)).to include(name: "Load boss", required: true)

      json = graphql(archive_role, { id: role.id })
      expect(json.dig(:data, :archiveCrewRole, :crewRole, :discardedAt)).to be_present
      expect(role.reload).to be_discarded
    end

    it "refuses a jumper" do
      expect { graphql(create_role, { attributes: { operatorId: operator.id, key: "mine", name: "Mine" } }, as: user) }.not_to change(CrewRole, :count)
      graphql(update_role, { id: roles.fetch("gca").id, attributes: { name: "Mine" } }, as: user)
      expect(roles.fetch("gca").reload.name).to eq("GCA")
    end
  end

  describe "the crew of a load" do
    let(:load_fields) { "id pilot { id } gca { id } crew { id crewRole { key } membership { id } loadVehicle { id } } isReady" }
    let(:create_load) { "mutation($attributes: LoadInput!) { createLoad(input: { attributes: $attributes }) { errors load { #{load_fields} } } }" }
    let(:update_load) { "mutation($id: ID!, $attributes: LoadInput!) { updateLoad(input: { id: $id, attributes: $attributes }) { errors load { #{load_fields} } } }" }

    def crew(pilot_member: pilot, gca_member: owner)
      [
        { crewRoleId: roles.fetch("pilot").id, membershipId: pilot_member.id, vehicleId: vehicle.id },
        { crewRoleId: roles.fetch("gca").id, membershipId: gca_member.id },
      ]
    end

    it "creates a load with its crew by role, and lists it" do
      json = graphql(create_load, { attributes: { vehicle: vehicle.id, crew: crew } })

      load = json.dig(:data, :createLoad, :load)
      expect(json.dig(:data, :createLoad, :errors)).to be_nil
      expect(load[:crew].map { |entry| entry.dig(:crewRole, :key) }).to eq(%w(pilot gca))
      expect(load[:crew][0][:loadVehicle]).to be_present
      expect(load[:crew][1][:loadVehicle]).to be_nil
      expect(load).to include(pilot: { id: pilot.id.to_s }, gca: { id: owner.id.to_s })
    end

    it "asks for the roles that are required" do
      json = graphql(create_load, { attributes: { vehicle: vehicle.id, crew: crew.take(1) } })

      expect(json.dig(:data, :createLoad, :load)).to be_nil
      expect(json.dig(:data, :createLoad, :errors)).to eq(["Every load needs a GCA"])
    end

    it "refuses somebody who may not fill the role" do
      jumper = create(:membership, operator: operator)

      json = graphql(create_load, { attributes: { vehicle: vehicle.id, crew: crew(pilot_member: jumper) } })

      expect(json.dig(:data, :createLoad, :load)).to be_nil
      expect(json.dig(:data, :createLoad, :errors).join).to include("cannot act as Pilot")
    end

    it "replaces the crew of a load" do
      id = graphql(create_load, { attributes: { vehicle: vehicle.id, crew: crew } }).dig(:data, :createLoad, :load, :id)
      other = create(:membership, operator: operator).tap { |member| member.grant!(:actAsPilot) }

      json = graphql(update_load, { id: id, attributes: { crew: crew(pilot_member: other) } })

      expect(json.dig(:data, :updateLoad, :load, :pilot, :id)).to eq(other.id.to_s)
      expect(Load.find(id).crew_assignments.count).to eq(2)
    end

    it "still takes the pilot and the GCA by themselves" do
      json = graphql(create_load, { attributes: { vehicle: vehicle.id, pilot: pilot.id, gca: owner.id } })

      expect(json.dig(:data, :createLoad, :load, :crew).size).to eq(2)
    end
  end
end
