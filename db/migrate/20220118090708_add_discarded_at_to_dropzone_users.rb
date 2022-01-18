# frozen_string_literal: true

class AddDiscardedAtToDropzoneUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :dropzone_users, :discarded_at, :datetime
    add_index :dropzone_users, :discarded_at
  end
end
