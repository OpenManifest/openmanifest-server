# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Client operations: destinations" do
  include_context "operator"

  let(:owner_user) { create(:user) }
  let!(:owner) { create(:membership, operator: operator, user: owner_user, user_role: operator.user_roles.find_by(name: "owner"), credits: 500) }
  let!(:hop) { Destination.altitude_for(operator, 4000) }
  let!(:full) { Destination.altitude_for(operator, 14_000) }

  describe "Destinations" do
    it "lists the operator's destinations by name" do
      json = client_operation("Destinations", variables: { operatorId: operator.id }, as: user)

      destinations = json.dig(:data, :operator, :destinations)
      expect(destinations.pluck(:name)).to eq(["Full altitude", "Hop n Pop"])
      expect(destinations.last).to include(kind: "altitude", altitudeM: 1219.2, altitudeFt: 4000)
    end

    it "leaves out archived destinations" do
      hop.discard

      json = client_operation("Destinations", variables: { operatorId: operator.id }, as: user)

      expect(json.dig(:data, :operator, :destinations).pluck(:name)).to eq(["Full altitude"])
    end
  end

  describe "CreateDestination" do
    it "creates an altitude from feet" do
      json = nil
      expect do
        json = client_operation("CreateDestination", variables: { attributes: { operatorId: operator.id, kind: "altitude", name: "Wingsuit", altitudeFt: 12_000 } }, as: owner_user)
      end.to change(Destination, :count).by(1)

      expect(json.dig(:data, :createDestination, :destination)).to include(name: "Wingsuit", kind: "altitude", altitudeM: 3657.6, altitudeFt: 12_000)
    end

    it "answers a kind the template does not offer with an error" do
      json = nil
      expect do
        json = client_operation("CreateDestination", variables: { attributes: { operatorId: operator.id, kind: "site", name: "Reef" } }, as: owner_user)
      end.not_to change(Destination, :count)

      expect(json.dig(:data, :createDestination, :destination)).to be_nil
      expect(json.dig(:data, :createDestination, :fieldErrors, 0, :field)).to eq("kind")
    end

    it "refuses a jumper" do
      expect do
        client_operation("CreateDestination", variables: { attributes: { operatorId: operator.id, kind: "altitude", name: "Mine", altitudeM: 100 } }, as: user)
      end.not_to change(Destination, :count)
    end
  end

  describe "UpdateDestination" do
    it "renames it and changes its height" do
      json = client_operation("UpdateDestination", variables: { id: hop.id, attributes: { name: "Low", altitudeM: 1000 } }, as: owner_user)

      expect(json.dig(:data, :updateDestination, :destination)).to include(name: "Low", altitudeM: 1000.0)
      expect(hop.reload.name).to eq("Low")
    end

    it "never moves to another operator" do
      other = create(:operator)

      client_operation("UpdateDestination", variables: { id: hop.id, attributes: { operatorId: other.id } }, as: owner_user)

      expect(hop.reload.operator).to eq(operator)
    end

    it "refuses a jumper" do
      client_operation("UpdateDestination", variables: { id: hop.id, attributes: { name: "Mine" } }, as: user)

      expect(hop.reload.name).to eq("Hop n Pop")
    end
  end

  describe "ArchiveDestination" do
    it "archives it and takes it off the ticket types" do
      ticket = create(:ticket_type, operator: operator, default_destination: hop)

      json = client_operation("ArchiveDestination", variables: { id: hop.id }, as: owner_user)

      expect(json.dig(:data, :archiveDestination, :errors)).to be_nil
      expect(hop.reload).to be_discarded
      expect(ticket.reload.default_destination).to be_nil
    end

    it "refuses a jumper" do
      client_operation("ArchiveDestination", variables: { id: hop.id }, as: user)

      expect(hop.reload).not_to be_discarded
    end
  end
end
