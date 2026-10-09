# frozen_string_literal: true

# Optimistic locking (BUG-024): Rails raises StaleObjectError when a load or slot is saved from an older version than the
# one in the database. Existing rows start at version 0.
class AddLockVersionToLoadsAndSlots < ActiveRecord::Migration[8.1]
  def change
    add_column :loads, :lock_version, :integer, default: 0, null: false
    add_column :slots, :lock_version, :integer, default: 0, null: false
  end
end
