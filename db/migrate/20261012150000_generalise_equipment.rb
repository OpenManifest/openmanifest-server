# frozen_string_literal: true

# P7.14 (GENERALISATION §9): rigs become equipment of operator-defined kinds. The kind's attribute schema validates the
# item's `properties` (the skydiving rig keeps its type, canopy size in m² and pack value there); the reserve repack date
# is the service date; the inspection form belongs to the kind; a slot can use several items. Reversible.
class GeneraliseEquipment < ActiveRecord::Migration[8.1]
  SQUARE_METRES_PER_SQUARE_FOOT = 0.09290304
  RIG_TYPES = %w(student sport tandem).freeze
  # The schema of the skydiving `rig` kind (config/industries/skydiving/presets.yml has the same)
  RIG_SCHEMA = {
    "rig_type" => { "label" => "Rig type", "type" => "enum", "values" => RIG_TYPES, "default" => "sport", "operator_only" => true, "not_rentable" => ["tandem"] },
    "canopy_size_m2" => { "label" => "Main canopy size", "type" => "decimal", "min" => 0, "unit" => "area" },
    "pack_value" => { "label" => "Pack value", "type" => "integer", "min" => 0 },
  }.freeze
  POLYMORPHIC = {
    active_storage_attachments: %i(record_type),
    events: %i(resource_type),
    notifications: %i(resource_type),
    orders: %i(seller_type buyer_type item_type),
    transactions: %i(sender_type receiver_type),
  }.freeze
  CLASSES = { "RigInspection" => "EquipmentInspection", "Rig" => "Equipment" }.freeze
  SETTINGS = { "require_rig_inspection" => "require_equipment_inspection", "require_reserve_in_date" => "require_equipment_in_service" }.freeze

  def up
    create_table :equipment_kinds do |t|
      t.references :operator, null: false, foreign_key: true
      t.string :key, null: false
      t.string :name, null: false
      t.jsonb :attribute_schema, null: false, default: {}
      t.integer :service_interval_days
      t.references :inspection_form_template, foreign_key: { to_table: :form_templates }
      t.integer :inspection_valid_days
      t.jsonb :required_by, null: false, default: {}
      t.integer :position, null: false, default: 0
      t.datetime :discarded_at, precision: nil
      t.timestamps
    end
    add_index :equipment_kinds, [:operator_id, :key], unique: true, where: "discarded_at IS NULL", name: "index_equipment_kinds_on_operator_and_key"

    rename_table :rigs, :equipment
    rename_table :rig_inspections, :equipment_inspections
    rename_column :equipment_inspections, :rig_id, :equipment_id
    rename_column :packs, :rig_id, :equipment_id
    rename_column :equipment, :repack_expires_at, :service_due_at
    rename_classes(CLASSES)

    add_reference :equipment, :kind, foreign_key: { to_table: :equipment_kinds }
    add_column :equipment, :ownership, :string, null: false, default: "personal"
    add_column :equipment, :properties, :jsonb, null: false, default: {}
    seed_rig_kinds
    move_rig_columns_to_properties
    remove_index :equipment, :rig_type
    remove_column :equipment, :rig_type, :integer
    remove_column :equipment, :canopy_size, :integer
    remove_column :equipment, :pack_value, :integer
    remove_reference :operators, :rig_inspection_template, index: true, foreign_key: { to_table: :form_templates }

    create_table :slot_equipment do |t|
      t.references :slot, null: false, foreign_key: true
      t.references :equipment, null: false, foreign_key: { to_table: :equipment }
      t.timestamps
    end
    add_index :slot_equipment, [:slot_id, :equipment_id], unique: true
    execute <<~SQL.squish
      INSERT INTO slot_equipment (slot_id, equipment_id, created_at, updated_at)
      SELECT id, rig_id, NOW(), NOW() FROM slots WHERE rig_id IS NOT NULL
    SQL
    remove_reference :slots, :rig, index: true, foreign_key: { to_table: :equipment }

    rename_settings(SETTINGS)
    rename_permissions("OperatorRig", "OperatorEquipment")
  end

  def down
    rename_permissions("OperatorEquipment", "OperatorRig")
    rename_settings(SETTINGS.invert)

    add_reference :slots, :rig, index: true, foreign_key: { to_table: :equipment }
    execute <<~SQL.squish
      UPDATE slots SET rig_id = first_item.equipment_id
      FROM (SELECT DISTINCT ON (slot_id) slot_id, equipment_id FROM slot_equipment ORDER BY slot_id, id) AS first_item
      WHERE slots.id = first_item.slot_id
    SQL
    drop_table :slot_equipment

    add_reference :operators, :rig_inspection_template, index: true, foreign_key: { to_table: :form_templates }
    execute <<~SQL.squish
      UPDATE operators SET rig_inspection_template_id = kinds.inspection_form_template_id
      FROM equipment_kinds kinds WHERE kinds.operator_id = operators.id AND kinds.key = 'rig'
    SQL
    add_column :equipment, :pack_value, :integer
    add_column :equipment, :canopy_size, :integer
    add_column :equipment, :rig_type, :integer
    add_index :equipment, :rig_type
    execute <<~SQL.squish
      UPDATE equipment SET
        rig_type = CASE properties ->> 'rig_type' WHEN 'student' THEN 0 WHEN 'sport' THEN 1 WHEN 'tandem' THEN 2 END,
        canopy_size = ROUND((properties ->> 'canopy_size_m2')::numeric / #{SQUARE_METRES_PER_SQUARE_FOOT}),
        pack_value = (properties ->> 'pack_value')::integer
    SQL
    remove_column :equipment, :properties
    remove_column :equipment, :ownership
    remove_reference :equipment, :kind, foreign_key: { to_table: :equipment_kinds }

    rename_classes(CLASSES.invert)
    rename_column :equipment, :service_due_at, :repack_expires_at
    rename_column :packs, :equipment_id, :rig_id
    rename_column :equipment_inspections, :equipment_id, :rig_id
    rename_table :equipment_inspections, :rig_inspections
    rename_table :equipment, :rigs
    drop_table :equipment_kinds
  end

  private

  # Every skydiving operator gets the rig kind, with the inspection form it had; a rig goes to the kind of its operator,
  # or of the first operator its owner is a member of
  def seed_rig_kinds
    execute <<~SQL.squish
      INSERT INTO equipment_kinds (operator_id, key, name, attribute_schema, service_interval_days, inspection_form_template_id,
                                   inspection_valid_days, required_by, position, created_at, updated_at)
      SELECT operators.id, 'rig', 'Rig', #{connection.quote(RIG_SCHEMA.to_json)}::jsonb, 180, operators.rig_inspection_template_id,
             NULL, '{"always": true}'::jsonb, 0, NOW(), NOW()
      FROM operators WHERE operators.industry = 'skydiving'
    SQL
    execute <<~SQL.squish
      UPDATE equipment SET kind_id = kinds.id, ownership = 'operator'
      FROM equipment_kinds kinds WHERE equipment.operator_id IS NOT NULL AND kinds.operator_id = equipment.operator_id AND kinds.key = 'rig'
    SQL
    execute <<~SQL.squish
      UPDATE equipment SET kind_id = (
        SELECT kinds.id FROM memberships JOIN equipment_kinds kinds ON kinds.operator_id = memberships.operator_id AND kinds.key = 'rig'
        WHERE memberships.user_id = equipment.user_id ORDER BY memberships.id LIMIT 1
      )
      WHERE equipment.kind_id IS NULL
    SQL
    execute <<~SQL.squish
      UPDATE equipment SET kind_id = (SELECT MIN(id) FROM equipment_kinds WHERE key = 'rig') WHERE equipment.kind_id IS NULL
    SQL
  end

  def move_rig_columns_to_properties
    execute <<~SQL.squish
      UPDATE equipment SET properties = jsonb_strip_nulls(jsonb_build_object(
        'rig_type', CASE rig_type WHEN 0 THEN 'student' WHEN 1 THEN 'sport' WHEN 2 THEN 'tandem' ELSE 'sport' END,
        'canopy_size_m2', CASE WHEN canopy_size IS NULL THEN NULL ELSE ROUND(canopy_size * #{SQUARE_METRES_PER_SQUARE_FOOT}::numeric, 4) END,
        'pack_value', pack_value
      ))
    SQL
  end

  def rename_classes(mapping)
    POLYMORPHIC.each do |table, columns|
      columns.each do |column|
        mapping.each { |from, to| execute "UPDATE #{table} SET #{column} = #{quote(to)} WHERE #{column} = #{quote(from)}" }
      end
    end
  end

  def rename_settings(mapping)
    mapping.each do |from, to|
      execute <<~SQL.squish
        UPDATE operators SET settings = (settings - #{quote(from)}) || jsonb_build_object(#{quote(to)}, settings -> #{quote(from)})
        WHERE settings ? #{quote(from)}
      SQL
    end
  end

  def rename_permissions(from, to)
    execute "UPDATE permissions SET name = REPLACE(name, #{quote(from)}, #{quote(to)}) WHERE name LIKE #{quote("%#{from}%")}"
  end
end
