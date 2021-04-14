class CreateLicenses < ActiveRecord::Migration[6.1]
  def change
    create_table :licenses do |t|
      t.string :name
      t.references :federation, null: false, foreign_key: true

      t.timestamps
    end
  end
end
