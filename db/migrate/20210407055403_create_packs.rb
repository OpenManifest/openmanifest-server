# frozen_string_literal: true

class CreatePacks < ActiveRecord::Migration[6.1]
  def change
    create_table :packs do |t|
      t.references :rig, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
