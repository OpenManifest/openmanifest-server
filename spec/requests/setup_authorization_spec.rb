# frozen_string_literal: true

require "rails_helper"

# P6.8: setup mutations authorise against the record's own operator and cannot move records between operators
# (BUG-009, BUG-010, BUG-039, BUG-061)
RSpec.describe "Setup authorization" do
  let(:operator_a) { create(:operator, state: "public") }
  let(:operator_b) { create(:operator, state: "public") }
  let(:owner_a_user) { create(:user) }
  let!(:owner_a) { create(:membership, operator: operator_a, user: owner_a_user, user_role: operator_a.user_roles.find_by(name: "owner")) }
  let(:owner_b_user) { create(:user) }
  let!(:owner_b) { create(:membership, operator: operator_b, user: owner_b_user, user_role: operator_b.user_roles.find_by(name: "owner")) }

  let!(:ticket_a) { create(:ticket_type, operator: operator_a, name: "Height A", cost: 40) }
  let!(:ticket_b) { create(:ticket_type, operator: operator_b, name: "Height B", cost: 50) }
  let!(:vehicle_b) { create(:vehicle, operator: operator_b, capacity: 12) }
  let!(:extra_a) { Extra.create!(operator: operator_a, name: "Video A", cost: 5) }
  let!(:extra_b) { Extra.create!(operator: operator_b, name: "Video B", cost: 6) }

  def graphql(query, as:, variables: {})
    post "/graphql", params: { query: query, variables: variables.to_json }, headers: as.create_new_auth_token
    response.parsed_body.with_indifferent_access
  end

  describe "records of another operator" do
    it "cannot be updated by the owner of an operator that sends its own operatorId" do
      client_operation("UpdateTicketType", variables: { id: ticket_b.id, attributes: { operatorId: operator_a.id, cost: 1.0 } }, as: owner_a_user)
      client_operation("UpdateVehicle", variables: { id: vehicle_b.id, attributes: { operatorId: operator_a.id, name: "Hijacked" } }, as: owner_a_user)
      client_operation("UpdateTicketAddon", variables: { id: extra_b.id, attributes: { operatorId: operator_a.id, name: "Hijacked" } }, as: owner_a_user)

      expect(ticket_b.reload).to have_attributes(cost: 50, operator_id: operator_b.id)
      expect(vehicle_b.reload.name).not_to eq("Hijacked")
      expect(extra_b.reload.name).to eq("Video B")
    end

    it "cannot have its form template changed through another operator's id" do
      template = operator_b.equipment_kinds.find_by!(key: "rig").inspection_form_template
      template.update!(definition: "original")

      client_operation("UpdateEquipmentInspectionTemplate", variables: { operatorId: operator_a.id, formId: template.id, definition: "hijacked" }, as: owner_a_user)

      expect(template.reload.definition).to eq("original")
    end

    it "cannot be edited through createExtra(id:) with the caller's operator" do
      # No client document sends an id to createExtra, so this is an ad-hoc mutation
      json = graphql("mutation($id: Int, $attributes: ExtraInput!) { createExtra(input: { id: $id, attributes: $attributes }) { errors extra { id } } }",
                     variables: { id: extra_b.id, attributes: { operatorId: operator_a.id, name: "Hijacked", cost: 0.0 } }, as: owner_a_user)

      expect(extra_b.reload.name).to eq("Video B")
      expect(json.dig(:data, :createExtra, :extra)).to be_nil
    end

    it "cannot be archived" do
      client_operation("ArchiveTicketType", variables: { id: ticket_b.id }, as: owner_a_user)
      client_operation("ArchiveVehicle", variables: { id: vehicle_b.id }, as: owner_a_user)

      expect(ticket_b.reload).not_to be_discarded
      expect(vehicle_b.reload).not_to be_discarded
    end

    it "cannot have its inspection result changed by an inspector of another operator" do
      member_b = create(:membership, operator: operator_b)
      equipment = create(:equipment, user: member_b.user, operator: nil)
      template = create(:form_template, operator: operator_b)
      inspection = EquipmentInspection.create!(equipment: equipment, membership: member_b, inspected_by: owner_b, form_template: template, definition: "x", is_ok: false)

      graphql("mutation($id: Int, $attributes: EquipmentInspectionInput!) { updateEquipmentInspection(input: { id: $id, attributes: $attributes }) { errors } }",
              variables: { id: inspection.id, attributes: { operator: operator_a.id, isOk: true } }, as: owner_a_user)

      expect(inspection.reload.is_ok).to be(false)
    end
  end

  describe "records of the caller's own operator" do
    it "keep their operator when an update names another" do
      client_operation("UpdateTicketType", variables: { id: ticket_a.id, attributes: { operatorId: operator_b.id, name: "Renamed" } }, as: owner_a_user)
      client_operation("UpdateTicketAddon", variables: { id: extra_a.id, attributes: { operatorId: operator_b.id, name: "Renamed" } }, as: owner_a_user)

      expect(ticket_a.reload).to have_attributes(name: "Renamed", operator_id: operator_a.id)
      expect(extra_a.reload).to have_attributes(name: "Renamed", operator_id: operator_a.id)
    end

    it "can be archived (ticket type)" do
      json = client_operation("ArchiveTicketType", variables: { id: ticket_a.id }, as: owner_a_user)

      expect(json.dig(:data, :archiveTicketType, :errors)).to be_nil
      expect(ticket_a.reload).to be_discarded
    end
  end

  describe "ticket type and add-on links" do
    it "only touch the record that is updated" do
      ticket_a2 = create(:ticket_type, operator: operator_a, name: "Other", cost: 10)
      extra_a2 = Extra.create!(operator: operator_a, name: "Coach", cost: 20)
      ticket_a2.extras << extra_a2

      client_operation("UpdateTicketType", variables: { id: ticket_a.id, attributes: { extraIds: [extra_a.id] } }, as: owner_a_user)
      client_operation("UpdateTicketAddon", variables: { id: extra_a.id, attributes: { ticketTypeIds: [ticket_a.id] } }, as: owner_a_user)

      expect(ticket_a.reload.extras).to eq([extra_a])
      expect(ticket_a2.reload.extras).to eq([extra_a2])
    end

    it "never link records of another operator" do
      client_operation("UpdateTicketType", variables: { id: ticket_a.id, attributes: { extraIds: [extra_a.id, extra_b.id] } }, as: owner_a_user)
      client_operation("UpdateTicketAddon", variables: { id: extra_a.id, attributes: { ticketTypeIds: [ticket_a.id, ticket_b.id] } }, as: owner_a_user)

      expect(ticket_a.reload.extras).to eq([extra_a])
      expect(extra_b.reload.ticket_types).to be_empty
      expect(ticket_b.reload.extras).to be_empty
    end
  end

  describe "archiving equipment" do
    it "lets staff archive an operator equipment of their operator but not of another" do
      equipment_a = create(:equipment, operator: operator_a, user: nil)
      equipment_b = create(:equipment, operator: operator_b, user: nil)

      client_operation("ArchiveEquipment", variables: { id: equipment_b.id }, as: owner_a_user)
      client_operation("ArchiveEquipment", variables: { id: equipment_a.id }, as: owner_a_user)

      expect(equipment_b.reload).not_to be_discarded
      expect(equipment_a.reload).to be_discarded
    end

    it "refuses a user archiving somebody else's equipment" do
      stranger_equipment = create(:equipment, user: create(:user), operator: nil)

      client_operation("ArchiveEquipment", variables: { id: stranger_equipment.id }, as: owner_a_user)

      expect(stranger_equipment.reload).not_to be_discarded
    end
  end

  it "has no context[:current_user] left (graphql_devise never sets it)" do
    expect(Rails.root.glob("app/**/*.rb").select { |file| File.read(file).include?("context[:current_user]") }).to be_empty
  end
end
