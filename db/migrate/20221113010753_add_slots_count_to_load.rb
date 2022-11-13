# frozen_string_literal: true

class AddSlotsCountToLoad < ActiveRecord::Migration[6.1]
  def change
    add_column :loads, :slots_count, :bigint, default: 0
    add_column :loads, :ready_slots_count, :bigint, default: 0
    add_index :loads, :slots_count
    add_index :loads, :ready_slots_count
  end
end
