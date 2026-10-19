# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Equipment kinds over GraphQL", type: :request do
  include_context "operator"

  let(:rig_kind) { operator.equipment_kinds.find_by!(key: "rig") }

  def run(query, as: user, **variables)
    post "/graphql", params: { query: query, variables: variables.to_json }, headers: as.create_new_auth_token
    response.parsed_body.with_indifferent_access
  end

  describe "Operator.equipmentKinds" do
    it "lists the kinds with their attribute schema and inspection form" do
      json = run("query($id: ID!) { operator(id: $id) { equipmentKinds { key name attributeSchema inspectionFormTemplate { id } } } }", id: operator.id)

      rig = json.dig(:data, :operator, :equipmentKinds).find { |kind| kind[:key] == "rig" }
      expect(rig[:attributeSchema].keys).to match_array(%w(rig_type canopy_size_m2 pack_value))
      expect(rig[:inspectionFormTemplate][:id]).to eq(rig_kind.inspection_form_template.id.to_s)
    end
  end

  describe "createEquipment" do
    let(:create_mutation) do
      "mutation($attributes: EquipmentInput!) { createEquipment(input: { attributes: $attributes }) { errors fieldErrors { field message } equipment { id attributes equipmentKind: kind { key } } } }"
    end

    it "stores the attributes of the kind" do
      json = run(create_mutation, attributes: { kindId: rig_kind.id.to_s, userId: user.id, make: "Vector", attributes: { rig_type: "student", canopy_size_m2: 15 } })

      equipment = json.dig(:data, :createEquipment, :equipment)
      expect(json.dig(:data, :createEquipment, :errors)).to be_nil
      expect(equipment[:equipmentKind][:key]).to eq("rig")
      expect(equipment[:attributes]).to include(rig_type: "student", canopy_size_m2: 15)
    end

    it "refuses a value that is not in the kind's schema" do
      expect do
        json = run(create_mutation, attributes: { kindId: rig_kind.id.to_s, userId: user.id, attributes: { rig_type: "hang glider" } })
        expect(json.dig(:data, :createEquipment, :fieldErrors, 0, :field)).to eq("properties")
      end.not_to change(Equipment, :count)
    end

    it "refuses a kind of another operator" do
      other_kind = create(:operator).equipment_kinds.find_by!(key: "rig")

      expect do
        run(create_mutation, attributes: { kindId: other_kind.id.to_s, userId: user.id })
      end.not_to change(Equipment, :count)
    end
  end

  describe "availableEquipment(kind:)" do
    let(:query) do
      "query($membership: Int!, $kind: String) { availableEquipment(membership: $membership, kind: $kind) { id } }"
    end
    let!(:rig) { create(:equipment, user: user, rig_type: :sport) }

    before { create(:equipment_inspection, is_ok: true, equipment: rig, membership: fun_jumper, inspected_by: instructor) }

    it "returns items of that kind" do
      json = run(query, membership: fun_jumper.id, kind: "rig")

      expect(json.dig(:data, :availableEquipment).pluck(:id)).to include(rig.id.to_s)
    end

    it "returns nothing for a kind the operator does not have" do
      json = run(query, membership: fun_jumper.id, kind: "wetsuit")

      expect(json.dig(:data, :availableEquipment)).to eq([])
    end
  end
end
