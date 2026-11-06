# frozen_string_literal: true

require "rails_helper"

# P7.12: the jump run and the exit spot are worked out in SI
RSpec.describe WeatherCondition, "jump run" do
  let(:operator) { create(:operator, lat: -27.5, lng: 152.9) }
  let(:condition) { operator.current_conditions }

  def winds(canopy:, freefall:)
    [
      { altitude_m: Units.to_si("altitude", 14_000, "ft"), speed_mps: freefall[0], direction: freefall[1] },
      { altitude_m: Units.to_si("altitude", 8000, "ft"), speed_mps: freefall[0], direction: freefall[1] },
      { altitude_m: Units.to_si("altitude", 2000, "ft"), speed_mps: canopy[0], direction: canopy[1] },
      { altitude_m: Units.to_si("altitude", 1000, "ft"), speed_mps: canopy[0], direction: canopy[1] },
    ].to_json
  end

  it "drifts 3.5 minutes at the speed of the winds, in metres" do
    condition.winds = winds(canopy: [5, 270], freefall: [5, 270])
    condition.guesstimate_jumprun

    expect(condition.jump_run).to eq(270)
    expect(condition.exit_spot_m).to eq(1050) # 5 m/s for 210 s
  end

  it "averages the direction of the canopy and of the freefall to 5 degrees" do
    condition.winds = winds(canopy: [4, 250], freefall: [8, 290])
    condition.guesstimate_jumprun

    expect(condition.jump_run).to eq(270)
    expect(condition.exit_spot_m).to eq(1260) # the mean of 840 m and 1680 m
  end

  it "leaves them alone when the winds are not usable" do
    condition.winds = "[]"
    condition.guesstimate_jumprun

    expect(condition.exit_spot_m).to be_nil
  end

  it "starts with calm winds at the usual heights in metres" do
    expect(condition.wind_list.pluck("altitude_m")).to eq([4267.2, 3048.0, 2133.6, 1524.0, 609.6])
    expect(condition.wind_list.pluck("speed_mps").uniq).to eq([0])
    expect(condition).to have_attributes(temperature_c: 0, offset_m: 0)
  end
end
