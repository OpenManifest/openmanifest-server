# frozen_string_literal: true

class AddStateToDropzones < ActiveRecord::Migration[6.1]
  def change
    add_column :dropzones, :state, :string, default: "private"
    add_index :dropzones, :state
  end
end
