class CreateDropzones < ActiveRecord::Migration[6.1]
  def change
    create_table :dropzones do |t|
      t.string :name
      t.references :federation
      t.float :lat
      t.float :lng

      t.timestamps
    end
  end
end
