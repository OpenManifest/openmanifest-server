require 'rails_helper'

RSpec.describe Transactions::Confirm do
  let!(:dropzone) { create(:dropzone, credits: 50) }
  let!(:ticket_type) { create(:ticket_type, dropzone: dropzone) }
  let!(:dropzone_user) { create(:dropzone_user, dropzone: dropzone, credits: 200) }
  let!(:receipt) { Transactions::Purchase.run(dropzone: dropzone, buyer: dropzone_user, seller: dropzone, purchasable: ticket_type).result.receipts.first }

  describe "Confirming a purchase" do
    let!(:outcome) { Transactions::Confirm.run(receipt: receipt) }

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
      expect(outcome.result.transactions.sum(:amount)).to eq 0
    end
    it "expect credits to be updated correctly" do
      expect(dropzone_user.reload.credits).to eq 200 - ticket_type.cost
      expect(dropzone.reload.credits).to eq 50 + ticket_type.cost
    end
  end
end
