# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Client operations: crew roles" do
  include_context "operator"

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
end
