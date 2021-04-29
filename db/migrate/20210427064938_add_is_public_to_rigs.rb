class AddIsPublicToRigs < ActiveRecord::Migration[6.1]
  def change
    add_column :rigs, :is_public, :boolean, default: false
  end
end
