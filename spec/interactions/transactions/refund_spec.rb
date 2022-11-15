# frozen_string_literal: true

require "rails_helper"

RSpec.describe Transactions::Refund do
  let!(:dropzone) { create(:dropzone, credits: 50) }
  let!(:ticket_type) { create(:ticket_type, dropzone: dropzone) }
  let!(:dropzone_user) { create(:dropzone_user, dropzone: dropzone, credits: 200) }
  let!(:access_context) do
    u = create(:dropzone_user, dropzone: dropzone)
    ::ApplicationInteraction::AccessContext.new(u)
  end
  let!(:order) { Transactions::Purchase.run(dropzone: dropzone, buyer: dropzone_user, seller: dropzone, purchasable: ticket_type, access_context: access_context) }

  describe "Refunding a purchase" do
    let!(:outcome) { Transactions::Refund.run(order: order.result, access_context: access_context) }

    it { expect(outcome.result).to be_a Order }
    it { expect(outcome.result.valid?).to be true }
    it { expect(outcome.result.receipts.count).to eq 2 }
    it { expect(outcome.result.transactions.count).to eq 4 }
    it { expect(outcome.result.transactions.where(status: :completed).count).to eq 4 }
    it { expect(outcome.result.transactions.where(transaction_type: :sale).count).to eq 1 }
    it { expect(outcome.result.transactions.where(transaction_type: :purchase).count).to eq 1 }
    it { expect(outcome.result.transactions.where(transaction_type: :refund).count).to eq 2 }
    it "expect transaction amounts to be correct" do
      outcome.result.transactions.each do |transaction|
        expect([ticket_type.cost, -1 * ticket_type.cost]).to include(transaction.amount)
      end
    end
    it "expects sum of transactions to always be 0" do
      expect(outcome.result.transactions.sum(:amount)).to eq 0
    end
    it "expect credits to be updated correctly" do
      expect(dropzone_user.reload.credits).to eq 200
      expect(dropzone.reload.credits).to eq 50
    end
  end
end
