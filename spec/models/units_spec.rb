# frozen_string_literal: true

require "rails_helper"

# P7.12: SI in the database and the API; every pair of display units converts to SI and back
RSpec.describe Units do
  # [quantity, unit, value in that unit, the SI value]
  cases = [
    ["altitude", "ft", 14_000, 4267.2],
    ["altitude", "m", 4267.2, 4267.2],
    ["depth", "ft", 100, 30.48],
    ["depth", "m", 18, 18],
    ["distance", "km", 2.5, 2500],
    ["distance", "nmi", 1, 1852],
    ["distance", "mi", 1, 1609.344],
    ["distance", "m", 750, 750],
    ["mass", "kg", 80, 80],
    ["mass", "lb", 176.37, 80.0001],
    ["area", "ft2", 150, 13.935456],
    ["area", "m2", 14, 14],
    ["speed", "kn", 10, 5.14444],
    ["speed", "kmh", 36, 10],
    ["speed", "mph", 10, 4.4704],
    ["speed", "mps", 7, 7],
    ["temperature", "c", 21, 21],
    ["temperature", "f", 70, 21.1111],
    ["temperature", "f", 32, 0],
  ]

  cases.each do |quantity, unit, value, si|
    it "turns #{value} #{unit} of #{quantity} into #{si} and back" do
      expect(described_class.to_si(quantity, value, unit)).to be_within(0.0001 * [si.abs, 1].max).of(si)
      expect(described_class.from_si(quantity, si, unit)).to be_within(0.0001 * [value.abs, 1].max).of(value)
    end
  end

  it "converts between two display units" do
    expect(described_class.convert("altitude", 14_000, from: "ft", to: "m")).to be_within(0.01).of(4267.2)
    expect(described_class.convert("speed", 10, from: "kn", to: "kmh")).to be_within(0.01).of(18.52)
    expect(described_class.convert("temperature", 100, from: "c", to: "f")).to be_within(0.001).of(212)
  end

  it "leaves a missing value missing" do
    expect(described_class.to_si("mass", nil, "lb")).to be_nil
    expect(described_class.from_si("temperature", nil, "f")).to be_nil
  end

  it "refuses a unit the quantity does not have" do
    expect { described_class.to_si("mass", 1, "ft") }.to raise_error(Units::UnknownUnit)
    expect { described_class.to_si("temperature", 1, "k") }.to raise_error(Units::UnknownUnit)
    expect { described_class.from_si("volume", 1, "l") }.to raise_error(KeyError)
  end

  it "lists what an operator can choose, without the SI unit of speed" do
    expect(described_class.supported("speed")).to eq(%w(kn kmh mph))
    expect(described_class.supported("mass")).to eq(%w(kg lb))
    expect(described_class.valid?("temperature", "f")).to be(true)
    expect(described_class.valid?("speed", "mps")).to be(false)
    expect(described_class.valid?("mass", "ft")).to be(false)
  end

  it "has a unit for every quantity the templates name" do
    Industry.all.each_value do |industry|
      industry.units.each { |quantity, unit| expect(described_class.valid?(quantity, unit)).to be(true), "#{industry.slug}: #{quantity} #{unit}" }
    end
  end
end
