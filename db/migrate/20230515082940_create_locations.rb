class CreateLocations < ActiveRecord::Migration[7.0]
  def change
    create_table :locations do |t|
      t.string :street_address
      t.text :full_address
      t.string :place_id
      t.string :state
      t.string :country
      t.string :city
      t.string :post_code
      t.float :lat
      t.float :lng

      t.timestamps
    end
    add_index :locations, :lat
    add_index :locations, :lng
  end
end
