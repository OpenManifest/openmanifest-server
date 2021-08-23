class AddCreditsToDropzone < ActiveRecord::Migration[6.1]
  def change
    add_column :dropzones, :credits, :integer
  end
end
