# frozen_string_literal: true

# P7.8: altitude becomes one kind of destination. An operator catalogues destinations; ticket types have a default one;
# a slot has its own (per-slot scope, skydiving) or a load visits an ordered list (per-load scope, everyone else).
# Existing altitudes (feet on the ticket type) become altitude destinations in metres, and existing slots take the one
# of their ticket type.
class CreateDestinations < ActiveRecord::Migration[8.1]
  FEET = 0.3048
  NAMES = { 4000 => "Hop n Pop", 14_000 => "Full altitude" }.freeze

  def up
    create_table :destinations do |t|
      t.references :operator, null: false, foreign_key: true
      t.string :kind, null: false, default: "altitude"
      t.string :name, null: false
      t.decimal :altitude_m, precision: 10, scale: 2
      t.jsonb :location, null: false, default: {}
      t.jsonb :stops, null: false, default: []
      t.integer :min_certification_rank
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :destinations, :discarded_at
    add_index :destinations, [:operator_id, :name], unique: true, where: "discarded_at IS NULL",
                                                    name: "index_destinations_on_operator_and_name"

    create_table :load_destinations do |t|
      t.references :load, null: false, foreign_key: true
      t.references :destination, null: false, foreign_key: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :load_destinations, [:load_id, :position], unique: true, name: "index_load_destinations_on_load_and_position"

    add_reference :slots, :destination, foreign_key: true
    add_reference :ticket_types, :default_destination, foreign_key: { to_table: :destinations }

    migrate_altitudes

    remove_column :ticket_types, :altitude
  end

  def down
    add_column :ticket_types, :altitude, :integer
    execute <<~SQL.squish
      UPDATE ticket_types SET altitude = ROUND(destinations.altitude_m / #{FEET})
      FROM destinations WHERE destinations.id = ticket_types.default_destination_id
    SQL
    remove_reference :ticket_types, :default_destination, foreign_key: { to_table: :destinations }
    remove_reference :slots, :destination, foreign_key: true
    drop_table :load_destinations
    drop_table :destinations
  end

  private

  # One destination per operator and altitude in use. The two usual ones get their names, the rest are named by height.
  def migrate_altitudes
    rows = select_rows("SELECT DISTINCT operator_id, altitude FROM ticket_types WHERE altitude IS NOT NULL AND altitude > 0")
    rows.each do |operator_id, altitude|
      feet = altitude.to_i
      name = NAMES.fetch(feet) { "#{feet} ft" }
      metres = (feet * FEET).round(2)
      destination_id = select_value(<<~SQL.squish)
        INSERT INTO destinations (operator_id, kind, name, altitude_m, location, stops, created_at, updated_at)
        VALUES (#{operator_id.to_i}, 'altitude', #{quote(name)}, #{metres}, '{}', '[]', NOW(), NOW())
        RETURNING id
      SQL
      execute "UPDATE ticket_types SET default_destination_id = #{destination_id.to_i} " \
              "WHERE operator_id = #{operator_id.to_i} AND altitude = #{feet}"
    end
    execute <<~SQL.squish
      UPDATE slots SET destination_id = ticket_types.default_destination_id
      FROM ticket_types WHERE ticket_types.id = slots.ticket_type_id AND ticket_types.default_destination_id IS NOT NULL
    SQL
  end
end
