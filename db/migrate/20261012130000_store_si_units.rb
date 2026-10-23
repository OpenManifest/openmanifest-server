# frozen_string_literal: true

# P7.12: weather is stored in SI (metres, metres per second, degrees Celsius) and every operator has a currency. The
# distances were miles, the winds knots at heights in feet; the columns are changed in place.
class StoreSiUnits < ActiveRecord::Migration[8.1]
  MILE = 1609.344
  KNOT = 1852.0 / 3600
  FOOT = 0.3048

  def up
    rename_column :weather_conditions, :exit_spot_miles, :exit_spot_m
    rename_column :weather_conditions, :offset_miles, :offset_m
    rename_column :weather_conditions, :temperature, :temperature_c
    change_column :weather_conditions, :exit_spot_m, :decimal, precision: 10, scale: 2, using: "exit_spot_m * #{MILE}"
    change_column :weather_conditions, :offset_m, :decimal, precision: 10, scale: 2, using: "offset_m * #{MILE}"
    change_column :weather_conditions, :temperature_c, :decimal, precision: 5, scale: 1

    convert_winds { |wind| wind_to_si(wind) }

    add_column :operators, :currency, :string, null: false, default: "AUD"
  end

  def down
    remove_column :operators, :currency

    convert_winds { |wind| wind_from_si(wind) }

    change_column :weather_conditions, :temperature_c, :integer, using: "ROUND(temperature_c)"
    change_column :weather_conditions, :offset_m, :decimal, precision: 6, scale: 2, using: "offset_m / #{MILE}"
    change_column :weather_conditions, :exit_spot_m, :decimal, precision: 6, scale: 2, using: "exit_spot_m / #{MILE}"
    rename_column :weather_conditions, :temperature_c, :temperature
    rename_column :weather_conditions, :offset_m, :offset_miles
    rename_column :weather_conditions, :exit_spot_m, :exit_spot_miles
  end

  private

  def convert_winds(&converter)
    select_rows("SELECT id, winds FROM weather_conditions WHERE winds IS NOT NULL").each do |id, winds|
      list = JSON.parse(winds)
      next unless list.is_a?(Array)

      execute "UPDATE weather_conditions SET winds = #{quote(list.map(&converter).to_json)} WHERE id = #{id.to_i}"
    rescue JSON::ParserError
      next
    end
  end

  # { altitude: "14000" (ft), speed | wind: 10 (kn), direction, temperature } → metres, metres per second
  def wind_to_si(wind)
    {
      "altitude_m" => (wind["altitude"].to_f * FOOT).round(2),
      "speed_mps" => ((wind["speed"] || wind["wind"]).to_f * KNOT).round(2),
      "direction" => wind["direction"],
      "temperature_c" => wind["temperature"],
    }
  end

  def wind_from_si(wind)
    {
      "altitude" => (wind["altitude_m"].to_f / FOOT).round.to_s,
      "speed" => (wind["speed_mps"].to_f / KNOT).round,
      "direction" => wind["direction"],
      "temperature" => wind["temperature_c"],
    }
  end
end
