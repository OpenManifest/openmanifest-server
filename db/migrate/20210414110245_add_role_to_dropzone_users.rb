# frozen_string_literal: true

class AddRoleToDropzoneUsers < ActiveRecord::Migration[6.1]
  def change
    remove_column :dropzone_users, :role
    add_reference :dropzone_users, :user_role, null: false, foreign_key: true
  end
end
