# frozen_string_literal: true

class AddDiscardedAtToLoad < ActiveRecord::Migration[6.1]
  def change
    add_column :loads, :discarded_at, :datetime
    add_index :loads, :discarded_at
  end
end
