# frozen_string_literal: true

require "rails_helper"

# P7.15: a ticket type that requires an escort takes up to `escort_capacity` guests for each escort: tandem 1:1, a try dive
# 1:4, a child with an adult. The guest's slot points to the escort's.
RSpec.describe "Escorts and guests" do
  let(:operator) { create(:operator, credits: 50) }
  let(:vehicle) { create(:vehicle, operator: operator, capacity: 8) }
  let(:gca) { create(:membership, operator: operator) }
  let(:pilot) { create(:membership, operator: operator) }
  let(:vehicle_load) { create(:load, vehicle: vehicle, gca: gca, pilot: pilot) }
  let(:other_load) { create(:load, vehicle: vehicle, gca: gca, pilot: pilot) }
  let(:escort) { create(:membership, operator: operator, credits: 500) }
  let(:ticket) { create(:ticket_type, operator: operator, name: "Tandem", requires_escort: true) }
  let(:access_context) do
    manifester = create(:membership, operator: operator)
    manifester.grant! :createSlot
    manifester.grant! :createUserSlot
    manifester.grant! :updateUserSlot
    manifester.grant! :deleteUserSlot
    ApplicationInteraction::AccessContext.new(manifester)
  end

  def guests(count) = Array.new(count) { |index| { name: "Guest #{index + 1}", body_mass_kg: 60 + index } }

  def manifest(on: vehicle_load, member: escort, ticket_type: ticket, guests: nil, **extra)
    Manifest::CreateSlot.run(
      access_context: access_context,
      ticket_type: ticket_type,
      membership: member,
      activity_type: ActivityType.allowed_for([member]).first,
      load: on,
      body_mass_kg: 80,
      guests: guests,
      **extra
    )
  end

  describe "one guest for each escort (tandem)" do
    it "puts the guest on a slot of the same load that points to the escort" do
      outcome = manifest(guests: [{ name: "Pat", body_mass_kg: 70, email: "pat@example.com", phone: "0400", date_of_birth: Date.new(1990, 5, 1), emergency_contact: "Sam 0411" }])

      expect(outcome).to be_valid
      slot = outcome.result
      guest_slot = slot.guest_slots.sole
      expect(guest_slot).to have_attributes(escort_slot: slot, load: vehicle_load, membership: nil, body_mass_kg: 70)
      expect(guest_slot.guest).to have_attributes(name: "Pat", email: "pat@example.com", phone: "0400", date_of_birth: Date.new(1990, 5, 1), emergency_contact: "Sam 0411", operator: operator)
      expect(vehicle_load.reload.slots_count).to eq(2)
    end

    it "takes no more than one guest" do
      expect { manifest(guests: guests(2)) }.not_to change(Slot, :count)
      outcome = manifest(guests: guests(2))

      expect(outcome).not_to be_valid
      expect(outcome.errors.full_messages.join).to match(/takes at most 1 guest/)
    end
  end

  describe "several guests for each escort (try dive)" do
    let(:ticket) { create(:ticket_type, operator: operator, name: "Try dive", requires_escort: true, escort_capacity: 4) }

    it "books four guests with one escort" do
      outcome = manifest(guests: guests(4))

      expect(outcome).to be_valid
      expect(outcome.result.guest_slots.map { |slot| slot.guest.name }).to eq(["Guest 1", "Guest 2", "Guest 3", "Guest 4"])
      expect(vehicle_load.reload.slots_count).to eq(5)
    end

    it "refuses a fifth guest, and books nothing" do
      outcome = nil
      expect { outcome = manifest(guests: guests(5)) }.not_to change(Slot, :count)

      expect(outcome.errors.full_messages.join).to match(/takes at most 4 guests/)
    end

    it "needs a seat for each of them" do
      vehicle_load.update_columns(max_slots: 4)

      outcome = manifest(guests: guests(4))

      expect(outcome).not_to be_valid
      expect(outcome.errors.full_messages.join).to match(/No slots available/)
    end

    it "replaces the guests when the member is manifested again" do
      slot = manifest(guests: guests(3)).result
      kept = slot.guest_slots.first

      outcome = manifest(guests: [{ name: "Renamed", body_mass_kg: 75 }])

      expect(outcome).to be_valid
      expect(outcome.result.reload.guest_slots.map(&:id)).to eq([kept.id])
      expect(kept.reload.guest.name).to eq("Renamed")
      expect(vehicle_load.reload.slots_count).to eq(2)
    end
  end

  describe "a ticket that takes no guests" do
    it "refuses guests" do
      plain = create(:ticket_type, operator: operator, name: "Height")
      outcome = manifest(ticket_type: plain, guests: guests(1))

      expect(outcome).not_to be_valid
      expect(outcome.errors.full_messages.join).to match(/does not take guests/)
    end
  end

  describe "the escort" do
    let(:qualification) { create(:qualification, certification_body: CertificationBody.find_by!(slug: "apf"), name: "Tandem rating") }
    let(:ticket) { create(:ticket_type, operator: operator, name: "Tandem", requires_escort: true, escort_qualification: qualification) }

    it "needs the qualification the ticket asks for" do
      outcome = manifest(guests: guests(1))

      expect(outcome).not_to be_valid
      expect(outcome.errors.full_messages.join).to match(/cannot escort guests: missing qualification/)
    end

    it "is cleared by holding it" do
      body = qualification.certification_body
      certification = create(:user_certification, user: escort.user, certification_body: body, certification_level: body.certification_levels.find_by!(name: "Certificate C"))
      create(:user_qualification, user_certification: certification, qualification: qualification, expires_at: 1.month.from_now)

      expect(manifest(guests: guests(1))).to be_valid
    end

    it "needs the permission of the crew role the ticket names" do
      role = operator.crew_roles.kept.find_by!(key: "pilot")
      guide = create(:ticket_type, operator: operator, name: "Guided", requires_escort: true, escort_crew_role: role)

      expect(manifest(ticket_type: guide, guests: guests(1))).not_to be_valid

      escort.grant!(role.permission)

      expect(manifest(ticket_type: guide, guests: guests(1))).to be_valid
    end

    it "needs no qualification for a child with an adult" do
      child_with_adult = create(:ticket_type, operator: operator, name: "Child with adult", requires_escort: true, escort_capacity: 2)

      outcome = manifest(ticket_type: child_with_adult, guests: [{ name: "Kid", body_mass_kg: 35, date_of_birth: 9.years.ago.to_date }])

      expect(outcome).to be_valid
    end

    it "must be a qualification of a body the operator accepts" do
      other = create(:qualification, certification_body: CertificationBody.create!(name: "Other", slug: "other-body", industry: "skydiving"))
      ticket = build(:ticket_type, operator: operator, name: "Odd", requires_escort: true, escort_qualification: other)

      expect(ticket).not_to be_valid
      expect(ticket.errors).to include(:escort_qualification)
    end
  end

  describe "a guest's slot" do
    it "rides on the load of its escort" do
      slot = manifest(guests: guests(1)).result
      guest_slot = slot.guest_slots.sole

      guest_slot.load = other_load

      expect(guest_slot).not_to be_valid
      expect(guest_slot.errors[:escort_slot]).to include("must be on the same load")
    end
  end

  describe "taking the escort off the load" do
    it "takes the guests with it" do
      slot = manifest(on: vehicle_load, ticket_type: create(:ticket_type, operator: operator, name: "Try dive", requires_escort: true, escort_capacity: 3), guests: guests(3)).result

      expect { Manifest::DeleteSlot.run!(access_context: access_context, slot: slot) }.to change(Slot, :count).by(-4)
    end
  end

  describe "moving the escort to another load" do
    let(:ticket) { create(:ticket_type, operator: operator, name: "Try dive", requires_escort: true, escort_capacity: 3) }

    it "moves the guests with it" do
      slot = manifest(guests: guests(3)).result

      outcome = Manifest::MoveSlot.run(access_context: access_context, source_slot: slot, target_load: other_load)

      expect(outcome).to be_valid
      expect(slot.reload.guest_slots.map(&:load_id).uniq).to eq([other_load.id])
      expect(vehicle_load.reload.slots_count).to eq(0)
      expect(other_load.reload.slots_count).to eq(4)
    end

    it "needs a seat for each of them on the other load" do
      slot = manifest(guests: guests(3)).result
      other_load.update_columns(max_slots: 3)

      outcome = Manifest::MoveSlot.run(access_context: access_context, source_slot: slot, target_load: other_load)

      expect(outcome).not_to be_valid
      expect(slot.reload.load).to eq(vehicle_load)
    end
  end
end
