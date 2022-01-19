# frozen_string_literal: true

class AddDiscardedAtToExtras < ActiveRecord::Migration[6.1]
  def change
    add_column :extras, :discarded_at, :datetime
    add_index :extras, :discarded_at
  end
end
