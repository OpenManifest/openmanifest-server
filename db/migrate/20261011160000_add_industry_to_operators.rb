# frozen_string_literal: true

# P7.7: every operator has a fixed industry (a template slug) and a set of module overrides; the time zone and the vehicle
# kind have no default any more (the template and the form provide them); roles carry the defaults that the constants
# UserRole::DEFAULT and DEFAULT_LICENSED used to hold; operators enable activity types.
class AddIndustryToOperators < ActiveRecord::Migration[8.1]
  def up
    add_column :operators, :industry, :string
    execute "UPDATE operators SET industry = 'skydiving'"
    change_column_null :operators, :industry, false
    add_column :operators, :modules, :jsonb, null: false, default: {}

    change_column_default :operators, :time_zone, from: "Australia/Brisbane", to: nil
    change_column_null :operators, :time_zone, false, "Australia/Brisbane"
    change_column_default :vehicles, :kind, from: "aircraft", to: nil

    add_column :user_roles, :is_default, :boolean, null: false, default: false
    add_column :user_roles, :is_default_certified, :boolean, null: false, default: false
    execute "UPDATE user_roles SET is_default = TRUE WHERE name = 'student'"
    execute "UPDATE user_roles SET is_default_certified = TRUE WHERE name = 'fun_jumper'"

    create_table :operator_activity_types do |t|
      t.references :operator, null: false, foreign_key: true
      t.references :activity_type, null: false, foreign_key: true
      t.timestamps
    end
    add_index :operator_activity_types, [:operator_id, :activity_type_id], unique: true, name: "index_operator_activity_types_uniqueness"
    execute <<~SQL.squish
      INSERT INTO operator_activity_types (operator_id, activity_type_id, created_at, updated_at)
      SELECT operators.id, activity_types.id, NOW(), NOW() FROM operators CROSS JOIN activity_types
    SQL
  end

  def down
    drop_table :operator_activity_types
    remove_column :user_roles, :is_default_certified
    remove_column :user_roles, :is_default
    change_column_default :vehicles, :kind, from: nil, to: "aircraft"
    change_column_null :operators, :time_zone, true
    change_column_default :operators, :time_zone, from: nil, to: "Australia/Brisbane"
    remove_column :operators, :modules
    remove_column :operators, :industry
  end
end
