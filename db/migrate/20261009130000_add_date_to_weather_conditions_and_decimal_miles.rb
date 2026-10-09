# frozen_string_literal: true

# A dropzone has one weather condition per local day (`date`, in the dropzone's time zone; the day used to be the UTC day
# of `created_at`), and distances are stored with decimals: a drift of 0.55 miles was truncated to 0 (BUG-045, BUG-046).
# Rows that end up on the same local day (the old keys were UTC midnights) are reduced to the most recently updated one.
class AddDateToWeatherConditionsAndDecimalMiles < ActiveRecord::Migration[8.1]
  INDEX = "index_weather_conditions_on_dropzone_id_and_date"

  def up
    add_column :weather_conditions, :date, :date
    backfill_dates
    remove_duplicate_days
    change_column_null :weather_conditions, :date, false
    add_index :weather_conditions, [:dropzone_id, :date], unique: true, name: INDEX

    change_column :weather_conditions, :exit_spot_miles, :decimal, precision: 6, scale: 2
    change_column :weather_conditions, :offset_miles, :decimal, precision: 6, scale: 2
  end

  def down
    change_column :weather_conditions, :offset_miles, :integer, using: "ROUND(offset_miles)::integer"
    change_column :weather_conditions, :exit_spot_miles, :integer, using: "ROUND(exit_spot_miles)::integer"

    remove_index :weather_conditions, name: INDEX
    remove_column :weather_conditions, :date
  end

  def backfill_dates
    select_rows("SELECT id, time_zone FROM dropzones").each do |dropzone_id, time_zone|
      zone = time_zone.presence || "Australia/Brisbane"
      zone = "Australia/Brisbane" unless select_value("SELECT 1 FROM pg_timezone_names WHERE name = #{quote(zone)}")
      execute "UPDATE weather_conditions SET date = (created_at AT TIME ZONE 'UTC' AT TIME ZONE #{quote(zone)})::date WHERE dropzone_id = #{dropzone_id.to_i}"
    end
  end

  def remove_duplicate_days
    ids = select_values(<<~SQL.squish).map(&:to_i)
      SELECT id FROM (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY dropzone_id, date ORDER BY updated_at DESC, id DESC) AS position
        FROM weather_conditions
      ) ranked
      WHERE position > 1
    SQL
    say "Removing #{ids.size} weather condition(s) of days that have a newer one: #{ids.inspect}"
    execute "DELETE FROM weather_conditions WHERE id IN (#{ids.join(',')})" if ids.any?
  end
end
