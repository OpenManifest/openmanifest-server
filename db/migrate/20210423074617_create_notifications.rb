class CreateNotifications < ActiveRecord::Migration[6.1]
  def change
    create_table :notifications do |t|
      t.string :message
      t.references :received_by, null: false, foreign_key: { to_table: :dropzone_users }
      t.references :sent_by, null: true, foreign_key: { to_table: :dropzone_users }
      t.references :resource, polymorphic: true, null: true
      t.integer :notification_type

      t.timestamps
    end
  end
end
