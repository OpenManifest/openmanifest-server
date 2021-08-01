# frozen_string_literal: true

class RemoveUserRoleFromPermission < ActiveRecord::Migration[6.1]
  def change
    remove_reference :permissions, :user_role
    remove_column :permissions, :name
    add_column :permissions, :name, :string
  end
end
