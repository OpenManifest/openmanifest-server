# frozen_string_literal: true

require "rails_helper"

RSpec.describe Loads::Finalize do
  let!(:dropzone) { create(:dropzone, credits: 50) }
  let!(:plane) { create(:plane, dropzone: dropzone, max_slots: 10) }
  let!(:ticket_type) { create(:ticket_type, dropzone: dropzone) }
  let!(:plane_load) { create(:load, plane: plane) }
  let!(:slots) do
    create_list(:dropzone_user_with_license, 6, dropzone: dropzone, credits: ticket_type.cost * 2).map do |dz_user|
      Manifest::CreateSlot.run(
        ticket_type_id: ticket_type.id,
        dropzone_user_id: dz_user.id,
        jump_type_id: JumpType.allowed_for([dz_user]).sample.id,
        load_id: plane_load.id,
        exit_weight: dz_user.exit_weight
      ).result
    end
  end

  describe "Cancelling a load" do
    let!(:outcome) do
      Loads::Cancel.run(
        load_id: plane_load.id
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
