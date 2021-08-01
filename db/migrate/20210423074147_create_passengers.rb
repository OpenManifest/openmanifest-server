# frozen_string_literal: true

class CreatePassengers < ActiveRecord::Migration[6.1]
  def change
    create_table :passengers do |t|
      t.string :name
      t.float :exit_weight
      t.references :dropzone, null: false, foreign_key: true

      t.timestamps
    end
  end
end
