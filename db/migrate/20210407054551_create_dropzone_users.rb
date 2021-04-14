class CreateDropzoneUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :dropzone_users do |t|
      t.references :user, null: false, foreign_key: true
      t.references :dropzone, null: false, foreign_key: true
      t.integer :role, index: true
      t.float :credits
      t.datetime :expires_at

      t.timestamps
    end
  end
end
