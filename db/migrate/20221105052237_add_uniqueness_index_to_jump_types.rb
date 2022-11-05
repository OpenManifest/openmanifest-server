# frozen_string_literal: true

class AddUniquenessIndexToJumpTypes < ActiveRecord::Migration[6.1]
  def change
    add_index :jump_types, :slug, unique: true
  end
end
