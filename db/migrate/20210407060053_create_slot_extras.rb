# frozen_string_literal: true

class CreateSlotExtras < ActiveRecord::Migration[6.1]
  def change
    create_table :slot_extras do |t|
      t.references :slot, null: false, foreign_key: true
      t.references :extra, null: false, foreign_key: true

      t.timestamps
    end
  end
end
