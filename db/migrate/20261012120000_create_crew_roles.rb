# frozen_string_literal: true

# P7.10: the pilot, GCA and load master of a load become crew roles defined per operator and assigned per load or per
# vehicle of the load. Every dropzone gets the three roles (the pilot per vehicle and required, the GCA per load and
# required, the load master per load); other operators get the roles their loads used. The three columns of `loads` move
# into `load_crew_assignments` and are dropped.
class CreateCrewRoles < ActiveRecord::Migration[8.1]
  ROLES = [
    { key: "pilot", name: "Pilot", scope: "vehicle", required: true, permission: "actAsPilot", position: 0 },
    { key: "gca", name: "GCA", scope: "load", required: true, permission: "actAsGCA", position: 1 },
    { key: "load_master", name: "Load master", scope: "load", required: false, permission: "actAsLoadMaster", position: 2 },
  ].freeze

  def up
    create_table :crew_roles do |t|
      t.references :operator, null: false, foreign_key: true
      t.string :key, null: false
      t.string :name, null: false
      t.string :scope, null: false, default: "load"
      t.boolean :required, null: false, default: false
      t.boolean :occupies_slot, null: false, default: false
      t.string :permission
      t.jsonb :vehicle_kinds, null: false, default: []
      t.integer :position, null: false, default: 0
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :crew_roles, [:operator_id, :key], unique: true, where: "discarded_at IS NULL", name: "index_crew_roles_on_operator_and_key"

    create_table :load_crew_assignments do |t|
      t.references :load, null: false, foreign_key: true
      t.references :load_vehicle, foreign_key: true
      t.references :crew_role, null: false, foreign_key: true
      t.references :membership, null: false, foreign_key: true
      t.timestamps
    end
    add_index :load_crew_assignments, [:load_id, :crew_role_id], unique: true, where: "load_vehicle_id IS NULL",
                                                                 name: "index_crew_assignments_per_load"
    add_index :load_crew_assignments, [:load_id, :load_vehicle_id, :crew_role_id], unique: true, where: "load_vehicle_id IS NOT NULL",
                                                                                   name: "index_crew_assignments_per_vehicle"

    migrate_crew

    remove_reference :loads, :gca, index: true, foreign_key: { to_table: :memberships }
    remove_reference :loads, :pilot, index: true, foreign_key: { to_table: :memberships }
    remove_reference :loads, :load_master, index: true, foreign_key: { to_table: :memberships }
  end

  def down
    add_reference :loads, :gca, index: true, foreign_key: { to_table: :memberships }
    add_reference :loads, :pilot, index: true, foreign_key: { to_table: :memberships }
    add_reference :loads, :load_master, index: true, foreign_key: { to_table: :memberships }
    ROLES.each do |role|
      execute <<~SQL.squish
        UPDATE loads SET #{role[:key]}_id = (
          SELECT load_crew_assignments.membership_id FROM load_crew_assignments
          JOIN crew_roles ON crew_roles.id = load_crew_assignments.crew_role_id
          WHERE load_crew_assignments.load_id = loads.id AND crew_roles.key = '#{role[:key]}'
          ORDER BY load_crew_assignments.id LIMIT 1
        )
      SQL
    end
    drop_table :load_crew_assignments
    drop_table :crew_roles
  end

  private

  def migrate_crew
    ROLES.each do |role|
      column = "#{role[:key]}_id"
      execute <<~SQL.squish
        INSERT INTO crew_roles (operator_id, key, name, scope, required, occupies_slot, permission, vehicle_kinds, position, created_at, updated_at)
        SELECT operators.id, #{quote(role[:key])}, #{quote(role[:name])}, #{quote(role[:scope])},
               operators.industry = 'skydiving' AND #{role[:required]}, FALSE, #{quote(role[:permission])}, '[]', #{role[:position]}, NOW(), NOW()
        FROM operators
        WHERE operators.industry = 'skydiving'
           OR EXISTS (SELECT 1 FROM loads WHERE loads.operator_id = operators.id AND loads.#{column} IS NOT NULL)
      SQL
      join = role[:scope] == "vehicle" ? "LEFT JOIN load_vehicles ON load_vehicles.load_id = loads.id AND load_vehicles.role = 'carrying' AND load_vehicles.position = 0" : ""
      vehicle_column = role[:scope] == "vehicle" ? "load_vehicles.id" : "NULL"
      execute <<~SQL.squish
        INSERT INTO load_crew_assignments (load_id, load_vehicle_id, crew_role_id, membership_id, created_at, updated_at)
        SELECT loads.id, #{vehicle_column}, crew_roles.id, loads.#{column}, NOW(), NOW()
        FROM loads
        #{join}
        JOIN crew_roles ON crew_roles.operator_id = loads.operator_id AND crew_roles.key = #{quote(role[:key])}
        WHERE loads.#{column} IS NOT NULL
      SQL
    end
  end
end
