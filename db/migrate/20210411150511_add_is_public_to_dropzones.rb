class AddIsPublicToDropzones < ActiveRecord::Migration[6.1]
  def change
    add_column :dropzones, :is_public, :boolean
  end
end
