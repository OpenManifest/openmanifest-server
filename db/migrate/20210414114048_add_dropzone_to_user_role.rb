class AddDropzoneToUserRole < ActiveRecord::Migration[6.1]
  def change
    add_reference :user_roles, :dropzone, null: false, foreign_key: true
  end
end
