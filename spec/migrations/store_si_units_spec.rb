# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/migrate/20261012130000_store_si_units")

# P7.12: the distances were miles, the winds knots at feet, the temperature an integer. The example goes back to the old
# columns inside its transaction, writes old values, migrates forward and reads SI.
RSpec.describe StoreSiUnits do
  let(:connection) { ActiveRecord::Base.connection }
  let(:operator) { create(:operator, lat: nil, lng: nil) }

  def quietly(&block) = ActiveRecord::Migration.suppress_messages(&block)

  def reset_models = [WeatherCondition, Operator].each(&:reset_column_information)

  after { reset_models }

  def old_weather
    operator
    quietly { described_class.new.migrate(:down) }
    reset_models
    winds = [{ altitude: "14000", speed: 10, direction: 270, temperature: 12 }, { altitude: 2000, wind: 5, direction: 90 }]
    connection.execute(<<~SQL.squish)
      INSERT INTO weather_conditions (operator_id, date, winds, temperature, jump_run, exit_spot_miles, offset_miles, offset_direction, created_at, updated_at)
      VALUES (#{operator.id}, '2026-10-12', #{connection.quote(winds.to_json)}, 12, 270, 0.67, 1.25, 90, NOW(), NOW())
    SQL
  end

  it "turns miles into metres, knots at feet into metres per second at metres, and keeps the direction" do
    old_weather

    quietly { described_class.new.migrate(:up) }
    reset_models

    condition = WeatherCondition.find_by!(operator_id: operator.id)
    expect(condition.exit_spot_m).to be_within(0.01).of(0.67 * 1609.344)
    expect(condition.offset_m).to be_within(0.01).of(1.25 * 1609.344)
    expect(condition.temperature_c).to eq(12)
    expect(condition.wind_list).to eq(
      [
        { "altitude_m" => 4267.2, "speed_mps" => 5.14, "direction" => 270, "temperature_c" => 12 },
        { "altitude_m" => 609.6, "speed_mps" => 2.57, "direction" => 90, "temperature_c" => nil },
      ]
    )
  end

  it "gives every operator the currency AUD" do
    old_weather
    quietly { described_class.new.migrate(:up) }
    reset_models

    expect(Operator.find(operator.id).currency).to eq("AUD")
  end

  it "goes back: miles, knots and feet again" do
    condition = operator.current_conditions
    condition.update!(exit_spot_m: 1609.34, winds: [{ altitude_m: 4267.2, speed_mps: 5.14, direction: 270, temperature_c: 12 }].to_json)

    quietly { described_class.new.migrate(:down) }

    row = connection.select_one("SELECT exit_spot_miles, winds FROM weather_conditions WHERE id = #{condition.id}")
    expect(row["exit_spot_miles"]).to be_within(0.01).of(1.0)
    expect(JSON.parse(row["winds"])).to eq([{ "altitude" => "14000", "speed" => 10, "direction" => 270, "temperature" => 12 }])
    expect(connection.column_exists?(:operators, :currency)).to be(false)
  end
end
