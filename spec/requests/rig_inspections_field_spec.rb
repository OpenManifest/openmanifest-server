# frozen_string_literal: true

require "rails_helper"

# BUG-102: Rig.rigInspections read an undefined local variable `rig` instead of the rig itself
RSpec.describe "Rig.rigInspections" do
  include_context "operator"

  let(:owner_user) { create(:user) }
  let!(:owner) { create(:membership, operator: operator, user: owner_user, user_role: operator.user_roles.find_by(name: "owner"), credits: 500) }
  let!(:rig) { create(:rig, operator: operator, user: user) }

  let(:query) do
    <<~GQL
      query($operatorId: ID!) {
        operator(id: $operatorId) {
          rigs {
            id
            rigInspections(operatorId: $operatorId) { id isOk inspectedBy { id } }
          }
        }
      }
    GQL
  end

  def rig_inspections
    post "/graphql", params: { query: query, variables: { operatorId: operator.id }.to_json }, headers: owner_user.create_new_auth_token
    response.parsed_body.with_indifferent_access
  end

  it "returns the inspection of the rig at the operator" do
    inspection = create(:rig_inspection, rig: rig, membership: fun_jumper, inspected_by: instructor)

    json = rig_inspections

    expect(json[:errors]).to be_nil
    expect(json.dig(:data, :operator, :rigs, 0, :rigInspections, :id)).to eq(inspection.id.to_s)
  end

  it "returns nothing for a rig that has not been inspected" do
    json = rig_inspections

    expect(json[:errors]).to be_nil
    expect(json.dig(:data, :operator, :rigs, 0, :rigInspections)).to be_nil
  end
end
