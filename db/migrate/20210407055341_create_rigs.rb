class CreateRigs < ActiveRecord::Migration[6.1]
  def change
    create_table :rigs do |t|
      t.string :make
      t.string :model
      t.string :serial
      t.integer :pack_value
      t.datetime :repack_expires_at
      t.datetime :maintained_at
      t.references :user, null: true, foreign_key: true

      t.timestamps
    end
  end
end
