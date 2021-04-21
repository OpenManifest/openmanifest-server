# frozen_string_literal: true

class RenameSlotsOnLoadToMaxSlots < ActiveRecord::Migration[6.1]
  def change
    remove_column :loads, :slots, :integer
    add_column :loads, :max_slots, :integer, default: 0
  end
end
