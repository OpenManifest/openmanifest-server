# frozen_string_literal: true

require "rails_helper"

# P7.15 over GraphQL, with the documents the client sends
RSpec.describe "Escorts over GraphQL", type: :request do
  include_context "operator"

  let(:owner_user) { create(:user) }
  let!(:owner) { create(:membership, operator: operator, user: owner_user, user_role: operator.user_roles.find_by(name: "owner"), credits: 500).tap { |member| %i(actAsGCA actAsLoadMaster).each { |permission| member.grant!(permission) } } }
  let!(:pilot) { create(:membership, operator: operator).tap { |member| member.grant!(:actAsPilot) } }
  let!(:manifest_load) { create(:load, vehicle: vehicle, pilot: pilot, gca: owner, load_master: owner, max_slots: 10) }
  let!(:try_dive) { create(:ticket_type, operator: operator, name: "Try dive", cost: 100).tap { |ticket| ticket.update!(requires_escort: true, escort_capacity: 3, allow_manifesting_self: false) } }

  def manifest(guests)
    client_operation("ManifestUser",
                     variables: {
                       load: manifest_load.id, membership: instructor.id, ticketType: try_dive.id, bodyMassKg: 80,
                       activityType: ActivityType.allowed_for([instructor]).first.id, guests: guests,
                     },
                     as: owner_user)
  end

  describe "CreateTicketType" do
    it "creates a ticket type that requires an escort, for several guests" do
      attributes = { name: "Child with adult", costCents: 5000, operatorId: operator.id, currency: "AUD", requiresEscort: true, escortCapacity: 2 }

      json = client_operation("CreateTicketType", variables: { attributes: attributes }, as: owner_user)

      expect(json.dig(:data, :createTicketType, :errors)).to be_nil
      expect(json.dig(:data, :createTicketType, :ticketType)).to include(requiresEscort: true, escortCapacity: 2, escortQualification: nil)
    end

    it "refuses a capacity below one" do
      attributes = { name: "None", costCents: 5000, operatorId: operator.id, currency: "AUD", requiresEscort: true, escortCapacity: 0 }

      expect { client_operation("CreateTicketType", variables: { attributes: attributes }, as: owner_user) }.not_to change(TicketType, :count)
    end
  end

  describe "ManifestUser" do
    let(:instructor) { create(:membership, operator: operator, credits: 500) }

    it "manifests an escort with several guests and returns them in order" do
      json = manifest([{ name: "Pat", bodyMassKg: 70, email: "pat@example.com", dateOfBirth: "1990-05-01" }, { name: "Sam", bodyMassKg: 80 }])

      expect(json.dig(:data, :createSlot, :errors)).to be_nil
      guest_slots = json.dig(:data, :createSlot, :slot, :guestSlots)
      expect(guest_slots.map { |slot| slot.dig(:guest, :name) }).to eq(%w(Pat Sam))
      expect(guest_slots.first[:guest]).to include(email: "pat@example.com", dateOfBirth: "1990-05-01")
      expect(manifest_load.reload.slots_count).to eq(3)
    end

    it "refuses more guests than the ticket takes" do
      json = nil
      expect { json = manifest(Array.new(4) { |index| { name: "Guest #{index}", bodyMassKg: 70 } }) }.not_to change(Slot, :count)

      expect(json.dig(:data, :createSlot, :errors).join).to match(/takes at most 3 guests/)
    end
  end
end
