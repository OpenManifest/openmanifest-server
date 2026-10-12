# frozen_string_literal: true

require "rails_helper"

RSpec.describe Transactions::Purchase do
  let!(:operator) { create(:operator, credits: 50) }
  let!(:ticket_type) { create(:ticket_type, operator: operator) }
  let!(:membership) { create(:membership, operator: operator, credits: 200) }
  let!(:access_context) do
    u = create(:membership, operator: operator)
    ApplicationInteraction::AccessContext.new(u)
  end

  describe "Creating a purchase" do
    let!(:outcome) do
      Transactions::Purchase.run(operator: operator, buyer: membership, seller: operator, purchasable: ticket_type,
                                 access_context: access_context)
    end

    it { expect(outcome.result).to be_a Order }
    it { expect(outcome.result.errors).to be_empty }
    it { expect(outcome.result.valid?).to be true }
    it { expect(outcome.result.receipts.count).to eq 1 }
    it { expect(outcome.result.transactions.count).to eq 2 }
    it { expect(outcome.result.transactions.where(status: :reserved).count).to eq 2 }
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
