# frozen_string_literal: true

class CreateChecklistValues < ActiveRecord::Migration[6.1]
  def change
    create_table :checklist_values do |t|
      t.references :checklist_item, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :dropzone_user }
      t.references :updated_by, null: false, foreign_key: { to_table: :dropzone_user }
      t.text :value, null: false
      t.timestamps
    end
  end
end
