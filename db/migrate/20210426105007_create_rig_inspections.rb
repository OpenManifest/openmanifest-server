# frozen_string_literal: true

class CreateRigInspections < ActiveRecord::Migration[6.1]
  def change
    create_table :rig_inspections do |t|
      t.references :form_template, null: false, foreign_key: true
      t.references :inspected_by, null: false, foreign_key: { to_table: :users }
      t.references :dropzone_user, null: false, foreign_key: true
      t.references :rig, null: false, foreign_key: true
      t.boolean :is_ok, null: false, default: false
      t.text :definition

      t.timestamps
    end
  end
end
