# frozen_string_literal: true

class AddExitWeightToSlots < ActiveRecord::Migration[6.1]
  def change
    add_column :slots, :exit_weight, :float
  end
end
