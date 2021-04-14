class CreateSlots < ActiveRecord::Migration[6.1]
  def change
    create_table :slots do |t|
      t.references :user, null: true, foreign_key: true
      t.references :ticket_type, null: true, foreign_key: true
      t.references :load, null: true, foreign_key: true
      t.references :rig, null: true, foreign_key: true
      t.references :jump_type, null: true, foreign_key: true

      t.timestamps
    end
  end
end
