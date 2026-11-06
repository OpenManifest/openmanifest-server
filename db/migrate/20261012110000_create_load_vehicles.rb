# frozen_string_literal: true

# P7.9: a load uses one or more vehicles, each carrying participants or supporting them (a tug, a chase vehicle). The
# vehicle of a load moves from `loads.vehicle_id` to `load_vehicles`, and a slot can be assigned to one of the carrying
# vehicles (with a counter per vehicle, like the one per load).
class CreateLoadVehicles < ActiveRecord::Migration[8.1]
  def up
    create_table :load_vehicles do |t|
      t.references :load, null: false, foreign_key: true
      t.references :vehicle, null: false, foreign_key: true
      t.string :role, null: false, default: "carrying"
      t.integer :position, null: false, default: 0
      t.integer :slots_count, null: false, default: 0
      t.timestamps
    end
    add_index :load_vehicles, [:load_id, :vehicle_id], unique: true, name: "index_load_vehicles_on_load_and_vehicle"
    add_index :load_vehicles, [:load_id, :position], name: "index_load_vehicles_on_load_and_position"

    execute <<~SQL.squish
      INSERT INTO load_vehicles (load_id, vehicle_id, role, position, slots_count, created_at, updated_at)
      SELECT id, vehicle_id, 'carrying', 0, 0, NOW(), NOW() FROM loads
    SQL

    add_reference :slots, :load_vehicle, foreign_key: true
    remove_reference :loads, :vehicle, index: true, foreign_key: true
  end

  def down
    add_reference :loads, :vehicle, index: true, foreign_key: true
    execute <<~SQL.squish
      UPDATE loads SET vehicle_id = (
        SELECT vehicle_id FROM load_vehicles
        WHERE load_vehicles.load_id = loads.id AND load_vehicles.role = 'carrying'
        ORDER BY position, id LIMIT 1
      )
    SQL
    change_column_null :loads, :vehicle_id, false
    remove_reference :slots, :load_vehicle, foreign_key: true
    drop_table :load_vehicles
  end
end
