# frozen_string_literal: true

class CreateFederations < ActiveRecord::Migration[6.1]
  def change
    create_table :federations do |t|
      t.string :name
      t.string :slug, unique: true

      t.timestamps
    end
  end
end
