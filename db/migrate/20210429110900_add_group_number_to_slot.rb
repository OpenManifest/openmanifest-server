class AddGroupNumberToSlot < ActiveRecord::Migration[6.1]
  def change
    add_column :slots, :group_number, :integer, null: false, default: 0
  end
end
