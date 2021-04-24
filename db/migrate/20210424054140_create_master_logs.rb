class CreateMasterLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :master_logs do |t|
      t.references :dzso, null: true, foreign_key: { to_table: :dropzone_users }
      t.references :dropzone, null: false, foreign_key: true
      t.text :notes

      t.timestamps
    end
  end
end
