# frozen_string_literal: true

require "rails_helper"

# BUG-048: money is integer cents
RSpec.describe Money do
  describe ".cents_of" do
    it "turns whole units into exact cents" do
      expect([12.5, 0.1, 19.99, 1.005, 40, "12.50", BigDecimal("3.30")].map { |units| described_class.cents_of(units) }).to eq([1250, 10, 1999, 101, 4000, 1250, 330])
    end

    it "is not fooled by the sums of floats" do
      expect(described_class.cents_of(0.1 + 0.2)).to eq(30)
    end

    it "keeps nil" do
      expect(described_class.cents_of(nil)).to be_nil
    end
  end

  it "adds and subtracts in cents" do
    expect((described_class.new(10) + described_class.new(20)).cents).to eq(30)
    expect((described_class.new(1250) - described_class.new(1251)).cents).to eq(-1)
  end

  it "compares" do
    expect(described_class.new(100)).to be > described_class.new(99)
    expect(described_class.new(100)).to eq(described_class.new(100))
  end

  it "formats" do
    expect([1250, 5, 100_000, 0, -300].map { |cents| described_class.new(cents).to_s }).to eq(["$12.50", "$0.05", "$1000.00", "$0.00", "-$3.00"])
  end

  it "gives whole units as a Float for older clients" do
    expect(described_class.new(1999).to_f).to eq(19.99)
  end
end

RSpec.describe MoneyAttributes do
  let(:dropzone) { create(:dropzone, credits: 0) }
  let(:member) { create(:dropzone_user, dropzone: dropzone) }

  it "stores the units a model is given as cents, and keeps the old column current" do
    member.update!(credits: 12.5)

    expect(member.reload.credits_cents).to eq(1250)
    expect(member.credits).to eq(12.5)
    expect(member.read_attribute(:credits)).to eq(12.5)
  end

  it "stores cents as given, and keeps the old column current" do
    member.update!(credits_cents: 1999)

    expect(member.reload.credits).to eq(19.99)
    expect(member.read_attribute(:credits)).to eq(19.99)
  end

  it "keeps nil (a member without a wallet)" do
    member.update!(credits: nil)

    expect(member.reload.credits_cents).to be_nil
    expect(member.credits).to be_nil
  end

  it "rounds units to the cent" do
    member.update!(credits: 0.1 + 0.2)

    expect(member.reload.credits_cents).to eq(30)
  end

  describe "#add_cents!" do
    before { member.update!(credits_cents: 1000) }

    it "adds and subtracts exactly" do
      member.add_cents!(:credits, 1250)
      member.add_cents!(:credits, -5)

      expect(member.reload.credits_cents).to eq(2245)
      expect(member.read_attribute(:credits)).to eq(22.45)
    end

    it "treats a missing wallet as empty" do
      member.update!(credits: nil)

      member.add_cents!(:credits, 500)

      expect(member.reload.credits_cents).to eq(500)
    end

    it "updates the object without making it dirty, so a later save does not write the value back" do
      member.add_cents!(:credits, 100)
      other = DropzoneUser.find(member.id)
      other.add_cents!(:credits, 200)

      member.update!(jump_count: 3)

      expect(member.reload.credits_cents).to eq(1300)
      expect(member).not_to be_changed
    end

    it "counts every addition of requests at the same time" do
      ids = Array.new(3) { DropzoneUser.find(member.id) }

      ids.each { |copy| copy.add_cents!(:credits, 100) }

      expect(member.reload.credits_cents).to eq(1300)
    end

    it "works for the dropzone's wallet too" do
      dropzone.add_cents!(:credits, 4250)

      expect(dropzone.reload.credits_cents).to eq(4250)
      expect(dropzone.credits).to eq(42.5)
    end
  end

  it "prices a slot from the cents of the ticket and the add-ons" do
    ticket = create(:ticket_type, dropzone: dropzone, cost: 12.5)
    video = Extra.create!(dropzone: dropzone, name: "Video", cost: 0.1)
    coach = Extra.create!(dropzone: dropzone, name: "Coach", cost: 0.2)
    plane_load = create(:load, plane: create(:plane, dropzone: dropzone))
    slot = Slot.new(load: plane_load, ticket_type: ticket, extras: [video, coach])

    expect(slot.cost_cents).to eq(1280)
    expect(slot.cost).to eq(12.8)
  end
end
