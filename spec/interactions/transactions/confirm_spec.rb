# frozen_string_literal: true

require "rails_helper"

RSpec.describe Transactions::Confirm do
  let!(:operator) { create(:operator, credits: 50) }
  let!(:ticket_type) { create(:ticket_type, operator: operator) }
  let!(:membership) { create(:membership, operator: operator, credits: 200) }
  let!(:access_context) do
    u = create(:membership, operator: operator)
    ApplicationInteraction::AccessContext.new(u)
  end
  let!(:receipt) do
    Transactions::Purchase.run(operator: operator, buyer: membership, seller: operator, purchasable: ticket_type,
                               access_context: access_context).result.receipts.first
  end

  describe "Confirming a purchase" do
    let!(:outcome) { Transactions::Confirm.run(receipt: receipt, access_context: access_context) }

    it { expect(outcome.result).to be_a Receipt }
    it { expect(outcome.result.valid?).to be true }
    it { expect(outcome.result.transactions.count).to eq 2 }
    it { expect(outcome.result.transactions.where(status: :reserved).count).to eq 0 }
    it { expect(outcome.result.transactions.where(status: :completed).count).to eq 2 }
    it "expect transaction amounts to be correct" do
      outcome.result.transactions.each do |transaction|
        expect([ticket_type.cost, -1 * ticket_type.cost]).to include(transaction.amount)
      end
    end
    it "expects sum of transactions to always be 0" do
      expect(outcome.result.transactions.sum(:amount_cents)).to eq 0
    end
    it "expect credits to be updated correctly" do
      expect(membership.reload.credits).to eq 200 - ticket_type.cost
      expect(operator.reload.credits).to eq 50 + ticket_type.cost
    end
  end
end
