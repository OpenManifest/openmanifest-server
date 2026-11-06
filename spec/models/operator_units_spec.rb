# frozen_string_literal: true

require "rails_helper"

# P7.12: the units an operator shows and the currency it sells in
RSpec.describe Operator, "units and currency" do
  let(:owner) { create(:user) }
  let(:dropzone) { Setup::Operators::CreateOperator.run!(owner: owner, industry: "skydiving", name: "DZ", time_zone: "Australia/Brisbane", certification_body_ids: [CertificationBody.first.id]) }
  let(:boats) { Setup::Operators::CreateOperator.run!(owner: owner, industry: "generic", name: "Boats", time_zone: "Australia/Brisbane") }

  it "shows the template's units until the operator picks its own" do
    expect(dropzone.units).to include("altitude" => "ft", "mass" => "kg", "speed" => "kn")
    expect(boats.units).to include("mass" => "kg", "temperature" => "c")
  end

  it "merges the units it picks over the template's" do
    dropzone.update!(settings: { units: { altitude: "m", mass: "lb" } })

    expect(dropzone.reload.units).to include("altitude" => "m", "mass" => "lb", "speed" => "kn")
  end

  it "refuses a unit the quantity does not have" do
    dropzone.settings = { units: { mass: "ft", speed: "mps", volume: "l" } }

    expect(dropzone).not_to be_valid
    expect(dropzone.errors.full_messages.join).to include("mass in ft", "speed in mps", "volume in l")
  end

  it "has a currency, AUD until it is set" do
    expect(dropzone.currency).to eq("AUD")
    dropzone.update!(currency: "NZD")

    expect(dropzone.reload.currency).to eq("NZD")
  end

  it "takes an ISO 4217 code only" do
    %w(aud AU AUDD 12A).each do |code|
      dropzone.currency = code

      expect(dropzone).not_to be_valid, "#{code} should be refused"
    end
  end
end
