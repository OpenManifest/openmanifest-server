class AddDropzoneIdToRigs < ActiveRecord::Migration[6.1]
  def change
    add_reference :rigs, :dropzone, null: true, foreign_key: true
  end
end
