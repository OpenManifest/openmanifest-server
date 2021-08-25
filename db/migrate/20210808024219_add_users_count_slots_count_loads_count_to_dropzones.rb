# frozen_string_literal: true

class AddUsersCountSlotsCountLoadsCountToDropzones < ActiveRecord::Migration[6.1]
  def self.up
    add_column :dropzones, :users_count, :integer, null: false, default: 0

    add_column :dropzones, :slots_count, :integer, null: false, default: 0

    add_column :dropzones, :loads_count, :integer, null: false, default: 0
  end

  def self.down
    remove_column :dropzones, :users_count

    remove_column :dropzones, :slots_count

    remove_column :dropzones, :loads_count
  end
end
