class CreateOrders < ActiveRecord::Migration[6.1]
  def change
    create_table :orders do |t|
      t.references :dropzone, null: false, foreign_key: true
      t.references :seller, polymorphic: true, null: false
      t.references :buyer, polymorphic: true, null: false
      t.references :item, polymorphic: true, null: false
      t.integer :order_number, null: false, default: 1
      t.timestamps
    end
    add_reference :receipts, :order
    remove_reference :receipts, :seller
    remove_reference :receipts, :buyer
    remove_reference :receipts, :item
    remove_column :receipts, :seller_type
    remove_column :receipts, :buyer_type
    remove_column :receipts, :item_type
  end
end
