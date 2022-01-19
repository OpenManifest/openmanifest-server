# frozen_string_literal: true

class AddDiscardedAtToRig < ActiveRecord::Migration[6.1]
  def change
    add_column :rigs, :discarded_at, :datetime
    add_index :rigs, :discarded_at
  end
end
