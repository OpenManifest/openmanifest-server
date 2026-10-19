# frozen_string_literal: true

require "rails_helper"

RSpec.describe Manifest::CreateSlot do
  let(:operator) { create(:operator, credits: 50) }
  let(:ticket_type) { create(:ticket_type, operator: operator) }

  let(:gca) { create(:membership, operator: operator, user: create(:user, name: "GCA")) }
  let(:pilot) { create(:membership, operator: operator, user: create(:user, name: "Pilot")) }
  let(:membership) { create(:membership, operator: operator, credits: 200) }
  let(:vehicle) { create(:vehicle, operator: operator) }
  let(:vehicle_load) { create(:load, vehicle: vehicle, gca: gca, pilot: pilot) }
  let(:access_context) do
    u = create(:membership, operator: operator)
    u.grant! :createSlot
    u.grant! :createUserSlot
    ApplicationInteraction::AccessContext.new(u)
  end

  describe "Manifesting on a load" do
    context "when the user has credits" do
      let!(:outcome) do
        Manifest::CreateSlot.run(
          access_context: access_context,
          ticket_type: ticket_type,
          membership: membership,
          activity_type: ActivityType.allowed_for([membership]).first,
          load: vehicle_load,
          body_mass_kg: membership.body_mass_kg
        )
      end

      it { expect(outcome.result).to be_a Slot }
      it { expect(outcome.errors).to be_empty }
      it { expect(outcome.valid?).to be true }
      it { expect(outcome.result.order).not_to be nil }
      it { expect(outcome.result.order.receipts.count).to eq 1 }
      it { expect(outcome.result.order.transactions.where(status: :reserved).count).to eq 2 }
    end

    context "when the user doesnt have enough credits" do
      before do
        membership.update(credits: ticket_type.cost - 10)
      end

      let!(:outcome) do
        Manifest::CreateSlot.run(
          access_context: access_context,
          ticket_type: ticket_type,
          membership: membership,
          activity_type: ActivityType.allowed_for([membership]).first,
          load: vehicle_load,
          body_mass_kg: membership.body_mass_kg
        )
      end

      it { expect(outcome.result).to be nil }
      it { expect(outcome.valid?).to be false }
      it { expect(outcome.errors).not_to be_empty }
      it { expect(outcome.errors.messages[:credits]).not_to be nil }
    end

    context "when the user isnt allowed to manifest with the requested jump type" do
      let!(:membership) do
        create(:membership, operator: operator, credits: 200, certification_body: CertificationBody.find_by(slug: :apf),
                            certification_level: CertificationBody.find_by(slug: :apf).certification_levels.find_by(name: "Certificate A"))
      end
      let!(:forbidden_activity_type) { ActivityType.where.not(id: ActivityType.allowed_for([membership]).pluck(:id)).sample }
      let!(:outcome) do
        Manifest::CreateSlot.run(
          access_context: access_context,
          ticket_type: ticket_type,
          membership: membership,
          activity_type: forbidden_activity_type,
          load: vehicle_load,
          body_mass_kg: membership.body_mass_kg
        )
      end

      it { expect(outcome.result).to be nil }
      it { expect(outcome.valid?).to be false }
      it { expect(outcome.errors).not_to be_empty }
      it { expect(outcome.errors.messages[:activity_type]).not_to be nil }
    end

    context "when the user is double manifested" do
      before do
        Manifest::CreateSlot.run(
          access_context: access_context,
          ticket_type: ticket_type,
          membership: membership,
          activity_type: ActivityType.allowed_for([membership]).first,
          load: vehicle_load,
          body_mass_kg: membership.body_mass_kg
        )
      end

      let!(:gca) { create(:membership, operator: operator) }
      let!(:pilot) { create(:membership, operator: operator) }
      let!(:second_load) { create(:load, vehicle: vehicle, gca: gca, pilot: pilot) }

      let!(:outcome) do
        Manifest::CreateSlot.run(
          access_context: access_context,
          ticket_type: ticket_type,
          membership: membership,
          activity_type: ActivityType.allowed_for([membership]).first,
          load: second_load,
          body_mass_kg: membership.body_mass_kg
        )
      end

      it { expect(outcome.result).not_to be_a Slot }
      it { expect(outcome.valid?).to be false }
      it { expect(outcome.errors).not_to be_empty }
      it { expect(outcome.errors.full_messages.first).to match(/double-manifest/i) }
    end

    context "when the user is double manifested but allowed to" do
      before { pending "BUG-033: createDoubleSlot only bypasses the check when allow_manifest_bypass is on, which the strict default settings turn off" }

      subject do
        Manifest::CreateSlot.run!(
          access_context: access_context,
          ticket_type: ticket_type,
          membership: membership,
          activity_type: ActivityType.allowed_for([membership]).first,
          load: second_load,
          body_mass_kg: membership.body_mass_kg
        )
      end

      before do
        Manifest::CreateSlot.run(
          access_context: access_context,
          ticket_type: ticket_type,
          membership: membership,
          activity_type: ActivityType.allowed_for([membership]).first,
          load: vehicle_load,
          body_mass_kg: membership.body_mass_kg
        )
        access_context.subject.grant! :createDoubleSlot
      end

      let!(:gca) { create(:membership, operator: operator) }
      let!(:pilot) { create(:membership, operator: operator) }
      let!(:second_load) { create(:load, vehicle: vehicle, gca: gca, pilot: pilot) }

      it { is_expected.to be_a Slot }
      it { expect { subject }.not_to raise_error }
    end

    context "with a tandem guest" do
      let(:tandem_ticket) { create(:ticket_type, operator: operator, requires_escort: true) }
      let(:outcome) do
        Manifest::CreateSlot.run(
          access_context: access_context,
          ticket_type: tandem_ticket,
          membership: membership,
          activity_type: ActivityType.allowed_for([membership]).first,
          load: vehicle_load,
          body_mass_kg: membership.body_mass_kg,
          guests: [{ name: Faker::Name.first_name, body_mass_kg: membership.body_mass_kg }]
        )
      end

      it { expect(outcome.result).to be_a Slot }
      it { expect(outcome.valid?).to be true }
      it { expect(outcome.errors).to be_empty }
      it { expect(outcome.result.guest_slots.size).to eq 1 }
      it { expect(outcome.result.order).not_to be nil }
      it { expect(outcome.result.order.receipts.count).to eq 2 }
      it { expect(outcome.result.order.transactions.where(status: :completed).count).to eq 4 }
    end

    context "when the database refuses a second slot for the same person on the load (BUG-021)" do
      let(:outcome) do
        Manifest::CreateSlot.run(
          access_context: access_context,
          ticket_type: ticket_type,
          membership: membership,
          activity_type: ActivityType.allowed_for([membership]).first,
          load: vehicle_load,
          body_mass_kg: membership.body_mass_kg
        )
      end

      before do
        allow_any_instance_of(Slot).to receive(:save).and_raise(ActiveRecord::RecordNotUnique)
      end

      it "reports an error instead of raising" do
        expect { outcome }.not_to raise_error
        expect(outcome.valid?).to be false
        expect(outcome.errors.full_messages).to include("Already manifested on this load")
      end

      it "does not charge the member" do
        expect { outcome }.not_to(change { membership.reload.credits })
      end
    end
  end

  describe "the unique index on (load, person)" do
    it "refuses two slots for the same person on one load" do
      slot = create(:slot, load: vehicle_load, operator: operator, membership: membership, activity_type: ActivityType.allowed_for([membership]).first)

      duplicate = slot.dup
      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "does not constrain guest slots, which have no member" do
      guest = Guest.create!(name: "Pat", body_mass_kg: 70, operator: operator)
      ticket = create(:ticket_type, operator: operator, requires_escort: true)
      slots = Array.new(2) { Slot.create!(load: vehicle_load, guest: guest, ticket_type: ticket, activity_type: ActivityType.first, body_mass_kg: 70) }

      expect(slots.map(&:membership_id)).to eq([nil, nil])
    end
  end

  describe "validations of a slot nobody created (BUG-034)" do
    it "does not raise when the creator is unknown" do
      slot = Slot.new(load: vehicle_load, membership: membership, ticket_type: ticket_type, body_mass_kg: 80,
                      activity_type: ActivityType.allowed_for([membership]).first, created_by: nil)

      expect { slot.valid? }.not_to raise_error
    end

    it "does not let an unknown creator bypass the credit check" do
      membership.update!(credits: 1)
      slot = Slot.new(load: vehicle_load, membership: membership, ticket_type: ticket_type, body_mass_kg: 80,
                      activity_type: ActivityType.allowed_for([membership]).first, created_by: nil)

      expect(slot).not_to be_valid
      expect(slot.errors.full_messages.join).to match(/credits/i)
    end
  end
end
