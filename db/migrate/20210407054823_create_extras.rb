class CreateExtras < ActiveRecord::Migration[6.1]
  def change
    create_table :extras do |t|
      t.float :cost
      t.string :name
      t.references :dropzone, null: false, foreign_key: true

      t.timestamps
    end
  end
end
