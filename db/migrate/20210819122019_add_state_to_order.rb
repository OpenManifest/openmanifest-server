class AddStateToOrder < ActiveRecord::Migration[6.1]
  def change
    add_column :orders, :state, :integer, index: true
  end
end
