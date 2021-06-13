class AddIsDeletedToExtras < ActiveRecord::Migration[6.1]
  def change
    add_column :extras, :is_deleted, :boolean, default: false
  end
end
