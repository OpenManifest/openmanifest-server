class CreateEvents < ActiveRecord::Migration[6.1]
  def change
    create_table :events do |t|
      t.references :resource, null: false, polymorphic: true
      t.integer :action, index: true
      t.integer :level, index: true
      t.integer :access_level, index: true
      t.references :dropzone_user, null: true, foreign_key: true
      t.references :dropzone, null: true, foreign_key: true
      t.text :message

      t.timestamps
    end
    add_index :events, :action, name: "index_event_actions"
  end
end
