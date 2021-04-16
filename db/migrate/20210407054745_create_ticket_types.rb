# frozen_string_literal: true

class CreateTicketTypes < ActiveRecord::Migration[6.1]
  def change
    create_table :ticket_types do |t|
      t.float :cost
      t.string :currency
      t.string :name
      t.references :dropzone, null: false, foreign_key: true
      t.integer :altitude
      t.boolean :allow_manifesting_self

      t.timestamps
    end
  end
end
