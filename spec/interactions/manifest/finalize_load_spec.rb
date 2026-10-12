# frozen_string_literal: true

require "rails_helper"

RSpec.describe Manifest::FinalizeLoad do
  include_context 'operator_with_load'
  let!(:ticket_type) { create(:ticket_type, operator: operator) }
  let!(:slots) do
    memberships = [
      create(:membership, operator: operator, credits: ticket_type.cost * 2),
      create(:membership, operator: operator, credits: ticket_type.cost * 2),
      create(:membership, operator: operator, credits: ticket_type.cost * 2),
      create(:membership, operator: operator, credits: ticket_type.cost * 2),
      create(:membership, operator: operator, credits: ticket_type.cost * 2),
      create(:membership, operator: operator, credits: ticket_type.cost * 2),
    ]
    memberships.filter_map do |dz_user|
      dz_user.update!(credits: ticket_type.cost * 2)
      o = Manifest::CreateSlot.run(
        access_context: access_context,
        ticket_type: ticket_type,
        membership: dz_user,
        activity_type: ActivityType.allowed_for([dz_user]).sample,
        load: load,
        body_mass_kg: dz_user.body_mass_kg
      )

      if o.valid?
        o.result
      else
        nil
      end
    end
  end
  let!(:access_context) do
    u = create(:membership, operator: operator)
    u.grant! :updateLoad
    # P6.5: manifesting somebody else needs createUserSlot
    u.grant! :createUserSlot
    ApplicationInteraction::AccessContext.new(u)
  end
  let!(:outcome) { Manifest::FinalizeLoad.run(load: load, access_context: access_context) }

  describe "Marking a load as completed" do
    it {
      expect(load.reload.slots.map(&:order).compact_blank.count).to eq 6
    }
    it { expect(outcome.result).to be_a Load }
    it { expect(outcome.valid?).to be true }
    it {
      puts outcome.errors.full_messages
      expect(outcome.errors).to be_empty
    }
    it "completes all transactions" do
      outcome.result.slots.each do |slot|
        expect(slot.order).not_to be nil
        expect(slot.order.receipts.count).to eq 1
        expect(slot.order.transactions.count).to eq 2
        expect(slot.membership.credits_cents).to eq((ticket_type.cost_cents * 2) - slot.cost_cents)
        expect(slot.order.transactions.where(status: :completed).count).to eq 2
      end
    end
  end
end
