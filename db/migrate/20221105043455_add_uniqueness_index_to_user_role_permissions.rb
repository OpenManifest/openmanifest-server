class AddUniquenessIndexToUserRolePermissions < ActiveRecord::Migration[6.1]
  def change
    add_index :permissions, :name, unique: true
    add_index :user_permissions, [:dropzone_user_id, :permission_id], unique: true
    add_index :user_role_permissions, [:user_role_id, :permission_id], unique: true
    add_index :user_roles, [:name, :dropzone_id], unique: true
  end
end
