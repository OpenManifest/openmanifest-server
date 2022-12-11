# frozen_string_literal: true

require "rails_helper"

RSpec.describe Manifest::FinalizeLoad do
  let!(:dropzone) { create(:dropzone, credits: 50) }
  let!(:plane) { create(:plane, dropzone: dropzone, max_slots: 10) }
  let!(:ticket_type) { create(:ticket_type, dropzone: dropzone) }
  let!(:gca) { create(:dropzone_user, dropzone: dropzone) }
  let!(:pilot) { create(:dropzone_user, dropzone: dropzone) }
  let!(:plane_load) { create(:load, plane: plane, pilot: pilot, gca: gca) }
  let!(:access_context) do
    u = create(:dropzone_user, dropzone: dropzone)
    u.grant! :deleteLoad
    u.grant! :createSlot
    u.grant! :createUserSlot
    ApplicationInteraction::AccessContext.new(u)
  end
  let!(:slots) do
    create_list(:dropzone_user, 6, dropzone: dropzone, credits: ticket_type.cost * 2).map do |dz_user|
      Manifest::CreateSlot.run(
        access_context: access_context,
        ticket_type: ticket_type,
        dropzone_user: dz_user,
        jump_type: JumpType.allowed_for([dz_user]).sample,
        load: plane_load,
        exit_weight: dz_user.exit_weight
      ).result
    end
  end

  describe "Cancelling a load" do
    let!(:outcome) do
      Manifest::CancelLoad.run(
        access_context: access_context,
        load: plane_load
      )
    end

    it { expect(outcome.result).to be_a Load }
    it { expect(outcome.valid?).to be true }
    it { expect(outcome.errors).to be_empty }
    it "completes all transactions" do
      outcome.result.slots.each do |slot|
        expect(slot.order).not_to be nil
        expect(slot.order.receipts.count).to eq 2
        expect(slot.order.transactions.count).to eq 4
        expect(slot.dropzone_user.credits).to eq(ticket_type.cost * 2)
        expect(slot.order.transactions.where(status: :completed).count).to eq 4
        expect(slot.order.transactions.where(transaction_type: :refund).count).to eq 2
      end
    end
  end
end
