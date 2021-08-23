class AddJumpCountDropzoneCountPlaneCountLoadCountToUsers < ActiveRecord::Migration[6.1]
  def self.up
    add_column :users, :jump_count, :integer, null: false, default: 0

    add_column :users, :dropzone_count, :integer, null: false, default: 0

    add_column :users, :plane_count, :integer, null: false, default: 0

  end

  def self.down
    remove_column :users, :jump_count

    remove_column :users, :dropzone_count

    remove_column :users, :plane_count

  end
end
