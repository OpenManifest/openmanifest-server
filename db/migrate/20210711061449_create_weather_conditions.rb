class CreateWeatherConditions < ActiveRecord::Migration[6.1]
  def change
    create_table :weather_conditions do |t|
      t.text :winds
      t.integer :temperature
      t.integer :jump_run
      t.integer :exit_spot_miles
      t.integer :offset_miles
      t.integer :offset_direction
      t.references :dropzone, null: false, foreign_key: true

      t.timestamps
    end
  end
end
