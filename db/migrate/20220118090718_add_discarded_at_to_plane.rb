# frozen_string_literal: true

class AddDiscardedAtToPlane < ActiveRecord::Migration[6.1]
  def change
    add_column :planes, :discarded_at, :datetime
    add_index :planes, :discarded_at
  end
end
