# frozen_string_literal: true

require "rails_helper"

RSpec.describe Manifest::FinalizeLoad do
  include_context 'dropzone_with_load'
  let!(:ticket_type) { create(:ticket_type, dropzone: dropzone) }
  let!(:access_context) do
    instructor.grant! :deleteLoad
    instructor.grant! :createSlot
    instructor.grant! :createUserSlot
    ApplicationInteraction::AccessContext.new(instructor)
  end
  let!(:slots) do
    create_list(:dropzone_user, 6, dropzone: dropzone, credits: ticket_type.cost * 2).map do |dz_user|
      Manifest::CreateSlot.run!(
        access_context: access_context,
        ticket_type: ticket_type,
        dropzone_user: dz_user,
        jump_type: JumpType.allowed_for([dz_user]).sample,
        load: load,
        exit_weight: dz_user.exit_weight
      )
    end
  end

  describe "Cancelling a load" do
    let!(:outcome) do
      Manifest::CancelLoad.run(
        access_context: access_context,
        load: load
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
