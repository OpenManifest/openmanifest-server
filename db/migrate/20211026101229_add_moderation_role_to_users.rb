class AddModerationRoleToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :moderation_role, :integer, default: 0
  end
end
