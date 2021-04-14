class AddDropzoneIdToPlanes < ActiveRecord::Migration[6.1]
  def change
    add_reference :planes, :dropzone, null: false, foreign_key: true
  end
end
