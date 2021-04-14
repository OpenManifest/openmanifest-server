class CreateLoads < ActiveRecord::Migration[6.1]
  def change
    create_table :loads do |t|
      t.datetime :dispatch_at
      t.boolean :has_landed
      t.references :plane, null: false, foreign_key: true
      t.references :load_master, null: true, foreign_key: { to_table: :users }
      t.references :gca, foreign_key: { to_table: :users }
      t.references :pilot, null: true, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
