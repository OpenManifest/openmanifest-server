# frozen_string_literal: true

class AddDiscardedAtToDropzone < ActiveRecord::Migration[6.1]
  def change
    add_column :dropzones, :discarded_at, :datetime
    add_index :dropzones, :discarded_at
  end
end
