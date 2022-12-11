# frozen_string_literal: true

class AddStateToOrder < ActiveRecord::Migration[6.1]
  def change
    add_column :orders, :state, :integer
    add_index :orders, :state
  end
end
