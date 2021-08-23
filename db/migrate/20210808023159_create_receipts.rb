class CreateReceipts < ActiveRecord::Migration[6.1]
  def change
    create_table :receipts do |t|
      t.integer :amount_cents
      t.references :seller, polymorphic: true, null: false
      t.references :buyer, polymorphic: true, null: false
      t.references :item, polymorphic: true, null: false

      t.timestamps
    end
  end
end
