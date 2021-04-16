# frozen_string_literal: true

class CreatePlanes < ActiveRecord::Migration[6.1]
  def change
    create_table :planes do |t|
      t.string :name
      t.integer :min_slots
      t.integer :max_slots
      t.integer :hours
      t.integer :next_maintenance_hours
      t.string :registration

      t.timestamps
    end
  end
end
