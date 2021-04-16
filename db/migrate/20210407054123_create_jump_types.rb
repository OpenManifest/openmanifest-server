# frozen_string_literal: true

class CreateJumpTypes < ActiveRecord::Migration[6.1]
  def change
    create_table :jump_types do |t|
      t.string :name
      t.string :slug, unique: true

      t.timestamps
    end
  end
end
