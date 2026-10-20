# frozen_string_literal: true

require "rails_helper"

# BUG-102: Equipment.equipmentInspections read an undefined local variable `equipment` instead of the equipment itself
RSpec.describe "Equipment.equipmentInspections" do
  include_context "operator"

  let(:owner_user) { create(:user) }
  let!(:owner) { create(:membership, operator: operator, user: owner_user, user_role: operator.user_roles.find_by(name: "owner"), credits: 500) }
  let!(:equipment) { create(:equipment, operator: operator, user: user) }

  let(:query) do
    <<~GQL
      query($operatorId: ID!) {
        operator(id: $operatorId) {
          equipment {
            id
            equipmentInspections(operatorId: $operatorId) { id isOk inspectedBy { id } }
          }
        }
      }
    GQL
  end

  def equipment_inspections
    post "/graphql", params: { query: query, variables: { operatorId: operator.id }.to_json }, headers: owner_user.create_new_auth_token
    response.parsed_body.with_indifferent_access
  end

  it "returns the inspection of the equipment at the operator" do
    inspection = create(:equipment_inspection, equipment: equipment, membership: fun_jumper, inspected_by: instructor)

    json = equipment_inspections

    expect(json[:errors]).to be_nil
    expect(json.dig(:data, :operator, :equipment, 0, :equipmentInspections, :id)).to eq(inspection.id.to_s)
  end

  it "returns nothing for a equipment that has not been inspected" do
    json = equipment_inspections

    expect(json[:errors]).to be_nil
    expect(json.dig(:data, :operator, :equipment, 0, :equipmentInspections)).to be_nil
  end
end
