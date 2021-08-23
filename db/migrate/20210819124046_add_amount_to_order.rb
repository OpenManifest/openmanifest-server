class AddAmountToOrder < ActiveRecord::Migration[6.1]
  def change
    add_column :orders, :amount, :float
  end
end
