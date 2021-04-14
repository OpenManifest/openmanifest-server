class CreateChecklistItems < ActiveRecord::Migration[6.1]
  def change
    create_table :checklist_items do |t|
      t.references :checklist, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :updated_by, null: false, foreign_key: { to_table: :users }
      t.integer :value_type
      t.boolean :is_required

      t.timestamps
    end
  end
end
