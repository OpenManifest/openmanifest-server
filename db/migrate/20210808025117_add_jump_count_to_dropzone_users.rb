class AddJumpCountToDropzoneUsers < ActiveRecord::Migration[6.1]
  def self.up
    add_column :dropzone_users, :jump_count, :integer, null: false, default: 0
  end

  def self.down
    remove_column :dropzone_users, :jump_count
  end
end
