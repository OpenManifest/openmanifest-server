class CreateUserRolePermissions < ActiveRecord::Migration[6.1]
  def change
    create_table :user_role_permissions do |t|
      t.references :permission, null: false, foreign_key: true
      t.references :user_role, null: false, foreign_key: true

      t.timestamps
    end
  end
end
