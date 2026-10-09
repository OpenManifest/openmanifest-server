# frozen_string_literal: true

require "rails_helper"

# P6.8: setup mutations authorise against the record's own dropzone and cannot move records between dropzones
# (BUG-009, BUG-010, BUG-039, BUG-061)
RSpec.describe "Setup authorization" do
  let(:dropzone_a) { create(:dropzone, state: "public") }
  let(:dropzone_b) { create(:dropzone, state: "public") }
  let(:owner_a_user) { create(:user) }
  let!(:owner_a) { create(:dropzone_user, dropzone: dropzone_a, user: owner_a_user, user_role: dropzone_a.user_roles.find_by(name: "owner")) }
  let(:owner_b_user) { create(:user) }
  let!(:owner_b) { create(:dropzone_user, dropzone: dropzone_b, user: owner_b_user, user_role: dropzone_b.user_roles.find_by(name: "owner")) }

  let!(:ticket_a) { create(:ticket_type, dropzone: dropzone_a, name: "Height A", cost: 40) }
  let!(:ticket_b) { create(:ticket_type, dropzone: dropzone_b, name: "Height B", cost: 50) }
  let!(:plane_b) { create(:plane, dropzone: dropzone_b, max_slots: 12) }
  let!(:extra_a) { Extra.create!(dropzone: dropzone_a, name: "Video A", cost: 5) }
  let!(:extra_b) { Extra.create!(dropzone: dropzone_b, name: "Video B", cost: 6) }

  def graphql(query, as:, variables: {})
    post "/graphql", params: { query: query, variables: variables.to_json }, headers: as.create_new_auth_token
    response.parsed_body.with_indifferent_access
  end

  describe "records of another dropzone" do
    it "cannot be updated by the owner of a dropzone that sends its own dropzoneId" do
      client_operation("UpdateTicketType", variables: { id: ticket_b.id, attributes: { dropzoneId: dropzone_a.id, cost: 1.0 } }, as: owner_a_user)
      client_operation("UpdateAircraft", variables: { id: plane_b.id, attributes: { dropzoneId: dropzone_a.id, name: "Hijacked" } }, as: owner_a_user)
      client_operation("UpdateTicketAddon", variables: { id: extra_b.id, attributes: { dropzoneId: dropzone_a.id, name: "Hijacked" } }, as: owner_a_user)

      expect(ticket_b.reload).to have_attributes(cost: 50, dropzone_id: dropzone_b.id)
      expect(plane_b.reload.name).not_to eq("Hijacked")
      expect(extra_b.reload.name).to eq("Video B")
    end

    it "cannot have its form template changed through another dropzone's id" do
      template = create(:form_template, dropzone: dropzone_b, definition: "original")
      dropzone_b.update!(rig_inspection_template: template)

      client_operation("UpdateRigInspectionTemplate", variables: { dropzoneId: dropzone_a.id, formId: template.id, definition: "hijacked" }, as: owner_a_user)

      expect(template.reload.definition).to eq("original")
    end

    it "cannot be edited through createExtra(id:) with the caller's dropzone" do
      # No client document sends an id to createExtra, so this is an ad-hoc mutation
      json = graphql("mutation($id: Int, $attributes: ExtraInput!) { createExtra(input: { id: $id, attributes: $attributes }) { errors extra { id } } }",
                     variables: { id: extra_b.id, attributes: { dropzoneId: dropzone_a.id, name: "Hijacked", cost: 0.0 } }, as: owner_a_user)

      expect(extra_b.reload.name).to eq("Video B")
      expect(json.dig(:data, :createExtra, :extra)).to be_nil
    end

    it "cannot be archived" do
      client_operation("ArchiveTicketType", variables: { id: ticket_b.id }, as: owner_a_user)
      client_operation("ArchivePlane", variables: { id: plane_b.id }, as: owner_a_user)

      expect(ticket_b.reload).not_to be_discarded
      expect(plane_b.reload).not_to be_discarded
    end

    it "cannot have its inspection result changed by an inspector of another dropzone" do
      member_b = create(:dropzone_user, dropzone: dropzone_b)
      rig = create(:rig, user: member_b.user, dropzone: nil)
      template = create(:form_template, dropzone: dropzone_b)
      inspection = RigInspection.create!(rig: rig, dropzone_user: member_b, inspected_by: owner_b, form_template: template, definition: "x", is_ok: false)

      graphql("mutation($id: Int, $attributes: RigInspectionInput!) { updateRigInspection(input: { id: $id, attributes: $attributes }) { errors } }",
              variables: { id: inspection.id, attributes: { dropzone: dropzone_a.id, isOk: true } }, as: owner_a_user)

      expect(inspection.reload.is_ok).to be(false)
    end
  end

  describe "records of the caller's own dropzone" do
    it "keep their dropzone when an update names another" do
      client_operation("UpdateTicketType", variables: { id: ticket_a.id, attributes: { dropzoneId: dropzone_b.id, name: "Renamed" } }, as: owner_a_user)
      client_operation("UpdateTicketAddon", variables: { id: extra_a.id, attributes: { dropzoneId: dropzone_b.id, name: "Renamed" } }, as: owner_a_user)

      expect(ticket_a.reload).to have_attributes(name: "Renamed", dropzone_id: dropzone_a.id)
      expect(extra_a.reload).to have_attributes(name: "Renamed", dropzone_id: dropzone_a.id)
    end

    it "can be archived (ticket type)" do
      json = client_operation("ArchiveTicketType", variables: { id: ticket_a.id }, as: owner_a_user)

      expect(json.dig(:data, :archiveTicketType, :errors)).to be_nil
      expect(ticket_a.reload).to be_discarded
    end
  end

  describe "ticket type and add-on links" do
    it "only touch the record that is updated" do
      ticket_a2 = create(:ticket_type, dropzone: dropzone_a, name: "Other", cost: 10)
      extra_a2 = Extra.create!(dropzone: dropzone_a, name: "Coach", cost: 20)
      ticket_a2.extras << extra_a2

      client_operation("UpdateTicketType", variables: { id: ticket_a.id, attributes: { extraIds: [extra_a.id] } }, as: owner_a_user)
      client_operation("UpdateTicketAddon", variables: { id: extra_a.id, attributes: { ticketTypeIds: [ticket_a.id] } }, as: owner_a_user)

      expect(ticket_a.reload.extras).to eq([extra_a])
      expect(ticket_a2.reload.extras).to eq([extra_a2])
    end

    it "never link records of another dropzone" do
      client_operation("UpdateTicketType", variables: { id: ticket_a.id, attributes: { extraIds: [extra_a.id, extra_b.id] } }, as: owner_a_user)
      client_operation("UpdateTicketAddon", variables: { id: extra_a.id, attributes: { ticketTypeIds: [ticket_a.id, ticket_b.id] } }, as: owner_a_user)

      expect(ticket_a.reload.extras).to eq([extra_a])
      expect(extra_b.reload.ticket_types).to be_empty
      expect(ticket_b.reload.extras).to be_empty
    end
  end

  describe "archiving rigs" do
    it "lets staff archive a dropzone rig of their dropzone but not of another" do
      rig_a = create(:rig, dropzone: dropzone_a, user: nil)
      rig_b = create(:rig, dropzone: dropzone_b, user: nil)

      client_operation("ArchiveRig", variables: { id: rig_b.id }, as: owner_a_user)
      client_operation("ArchiveRig", variables: { id: rig_a.id }, as: owner_a_user)

      expect(rig_b.reload).not_to be_discarded
      expect(rig_a.reload).to be_discarded
    end

    it "refuses a user archiving somebody else's rig" do
      stranger_rig = create(:rig, user: create(:user), dropzone: nil)

      client_operation("ArchiveRig", variables: { id: stranger_rig.id }, as: owner_a_user)

      expect(stranger_rig.reload).not_to be_discarded
    end
  end

  it "has no context[:current_user] left (graphql_devise never sets it)" do
    expect(Dir[Rails.root.join("app/**/*.rb")].select { |file| File.read(file).include?("context[:current_user]") }).to be_empty
  end
end
